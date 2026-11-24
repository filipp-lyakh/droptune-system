// Run with @electric-sql/pglite installed locally or PGLITE_DEPENDENCIES pointing
// to an isolated npm prefix. No production connection or credentials are used.
import fs from 'node:fs';
import {createRequire} from 'node:module';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url);
const {PGlite}=require(require.resolve('@electric-sql/pglite', {
  paths:[process.env.PGLITE_DEPENDENCIES || process.cwd()],
}));
const db=new PGlite();
const migration=fs.readFileSync(new URL('../supabase/migrations/20261125020000_add_backend_free_album_claim.sql',import.meta.url),'utf8');
const alignment=fs.readFileSync(new URL('../supabase/migrations/20260504195200_align_data_model_v1.sql',import.meta.url),'utf8');
const existingRpc=alignment.slice(alignment.indexOf('CREATE OR REPLACE FUNCTION public.claim_album_copy_for_user('),alignment.indexOf('CREATE OR REPLACE FUNCTION public.fulfill_payment_order('));
const id=n=>`00000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
try {
 await db.exec(`
  CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role;
  CREATE TABLE users(id uuid PRIMARY KEY);
  CREATE TABLE albums(id uuid PRIMARY KEY, price numeric);
  CREATE TABLE album_copies(id uuid PRIMARY KEY DEFAULT gen_random_uuid(), album_id uuid REFERENCES albums, serial integer, UNIQUE(album_id,serial));
  CREATE TABLE copy_ownership(copy_id uuid PRIMARY KEY REFERENCES album_copies,owner_user_id uuid REFERENCES users, acquired_at timestamptz,acquired_via text,last_tx_id uuid);
  CREATE TABLE transactions(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),copy_id uuid REFERENCES album_copies,from_user_id uuid,to_user_id uuid REFERENCES users,price numeric,currency text,type text,status text,created_at timestamptz,completed_at timestamptz);
 `);
 await db.exec(existingRpc);
 await db.exec(migration);
 await db.exec(migration); // rerunnable migration
 for(const n of [1,2,3]) await db.query('INSERT INTO users VALUES ($1)',[id(n)]);
 await db.query('INSERT INTO albums VALUES ($1,0),($2,10),($3,NULL)',[id(10),id(11),id(12)]);
 await db.query('INSERT INTO album_copies(album_id,serial) VALUES ($1,1),($1,2)',[id(10)]);
 const privilege=await db.query(`SELECT
  has_function_privilege('anon','public.claim_free_album_copy_for_user(uuid,uuid)','EXECUTE') AS anon,
  has_function_privilege('authenticated','public.claim_free_album_copy_for_user(uuid,uuid)','EXECUTE') AS authenticated,
  has_function_privilege('service_role','public.claim_free_album_copy_for_user(uuid,uuid)','EXECUTE') AS service_role`);
 assert.deepEqual(privilege.rows[0],{anon:false,authenticated:false,service_role:true});
 await db.exec('SET ROLE anon');
 await assert.rejects(db.query('SELECT * FROM claim_free_album_copy_for_user($1,$2)',[id(10),id(1)]),/permission denied/);
 await db.exec('RESET ROLE; SET ROLE service_role');
 const claim=(album,user)=>db.query('SELECT * FROM claim_free_album_copy_for_user($1,$2)',[album,user]);
 await assert.rejects(claim(id(11),id(1)),/Album is not free/);
 await assert.rejects(claim(id(12),id(1)),/Album is not free/);
 await assert.rejects(claim(id(99),id(1)),/Album not found/);
 await assert.rejects(claim(id(10),null),/User id is required/);
 // A failure after selection must not consume inventory or leave a transaction.
 await assert.rejects(claim(id(10),id(99)),/foreign key/);
 const first=(await claim(id(10),id(1))).rows[0];
 assert.equal(first.serial,1);
 assert.deepEqual((await claim(id(10),id(1))).rows[0],first);
 const second=(await claim(id(10),id(2))).rows[0];
 assert.equal(second.serial,2);assert.notEqual(first.copy_id,second.copy_id);
 await assert.rejects(claim(id(10),id(3)),/No copies left/);
 assert.deepEqual((await claim(id(10),id(1))).rows[0],first);
 await db.exec('RESET ROLE');
 assert.equal((await db.query('SELECT count(*)::integer AS count FROM copy_ownership')).rows[0].count,2);
 const audit=await db.query(`SELECT t.price,t.currency,t.status,t.type,co.acquired_via
  FROM transactions t JOIN copy_ownership co ON co.last_tx_id=t.id`);
 assert.equal(audit.rows.length,2);
 for(const row of audit.rows) assert.deepEqual(row,{price:'0',currency:'RUB',status:'completed',type:'primary',acquired_via:'admin_claim'});
 console.log('PASS: RPC privileges, zero/paid/null prices, invalid user rollback, idempotent retries, finite inventory and transaction history. Real multi-session concurrency still requires a staging smoke test.');
} finally {await db.close();}
