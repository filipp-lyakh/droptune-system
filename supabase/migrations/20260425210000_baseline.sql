


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."claim_album_copy"("p_album_id" "uuid", "p_price" numeric DEFAULT NULL::numeric, "p_currency" "text" DEFAULT NULL::"text") RETURNS TABLE("copy_id" "uuid", "serial" integer, "album_id" "uuid")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id uuid;
  v_copy_id uuid;
  v_serial integer;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select ac.id, ac.serial
  into v_copy_id, v_serial
  from public.album_copies ac
  where ac.album_id = p_album_id
    and not exists (
      select 1
      from public.copy_ownership co
      where co.copy_id = ac.id
    )
  order by ac.serial
  limit 1
  for update skip locked;

  if v_copy_id is null then
    raise exception 'No copies left';
  end if;

  insert into public.copy_ownership (
    copy_id,
    owner_user_id,
    acquired_at
  )
  values (
    v_copy_id,
    v_user_id,
    now()
  );

  insert into public.transactions (
    copy_id,
    from_user_id,
    to_user_id,
    price,
    currency,
    type,
    created_at
  )
  values (
    v_copy_id,
    null,
    v_user_id,
    p_price,
    p_currency,
    'primary',
    now()
  );

  return query
  select v_copy_id, v_serial, p_album_id;
end;
$$;


ALTER FUNCTION "public"."claim_album_copy"("p_album_id" "uuid", "p_price" numeric, "p_currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."claim_album_copy_for_user"("p_album_id" "uuid", "p_user_id" "uuid", "p_price" numeric DEFAULT NULL::numeric, "p_currency" "text" DEFAULT NULL::"text") RETURNS TABLE("copy_id" "uuid", "serial" integer, "album_id" "uuid")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_copy_id uuid;
  v_serial integer;
begin
  if p_user_id is null then
    raise exception 'User id is required';
  end if;

  select ac.id, ac.serial
  into v_copy_id, v_serial
  from public.album_copies ac
  where ac.album_id = p_album_id
    and not exists (
      select 1
      from public.copy_ownership co
      where co.copy_id = ac.id
    )
  order by ac.serial
  limit 1
  for update skip locked;

  if v_copy_id is null then
    raise exception 'No copies left';
  end if;

  insert into public.copy_ownership (
    copy_id,
    owner_user_id,
    acquired_at
  )
  values (
    v_copy_id,
    p_user_id,
    now()
  );

  insert into public.transactions (
    copy_id,
    from_user_id,
    to_user_id,
    price,
    currency,
    type,
    created_at
  )
  values (
    v_copy_id,
    null,
    p_user_id,
    p_price,
    p_currency,
    'primary',
    now()
  );

  return query
  select v_copy_id, v_serial, p_album_id;
end;
$$;


ALTER FUNCTION "public"."claim_album_copy_for_user"("p_album_id" "uuid", "p_user_id" "uuid", "p_price" numeric, "p_currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fulfill_payment_order"("p_order_id" "uuid") RETURNS TABLE("order_id" "uuid", "copy_id" "uuid", "serial" integer, "transaction_id" "uuid", "status" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_order record;
  v_copy_id uuid;
  v_serial integer;
  v_transaction_id uuid;
  v_existing_copy_id uuid;
begin
  -- Берём заказ и лочим его, чтобы не выполнить дважды
  select *
  into v_order
  from public.payment_orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Payment order not found';
  end if;

  -- Если уже fulfilled — просто возвращаем результат
  if v_order.status = 'fulfilled' then
    return query
    select
      v_order.id,
      v_order.copy_id,
      ac.serial,
      v_order.transaction_id,
      v_order.status
    from public.album_copies ac
    where ac.id = v_order.copy_id;
    return;
  end if;

  if v_order.status <> 'paid' then
    raise exception 'Payment order is not paid';
  end if;

  -- Проверяем, не владеет ли пользователь уже копией этого альбома
  select co.copy_id
  into v_existing_copy_id
  from public.copy_ownership co
  join public.album_copies ac on ac.id = co.copy_id
  where co.owner_user_id = v_order.user_id
    and ac.album_id = v_order.album_id
  limit 1;

  if v_existing_copy_id is not null then
    raise exception 'User already owns a copy of this album';
  end if;

  -- Находим первую свободную копию и лочим её
  select ac.id, ac.serial
  into v_copy_id, v_serial
  from public.album_copies ac
  where ac.album_id = v_order.album_id
    and not exists (
      select 1
      from public.copy_ownership co
      where co.copy_id = ac.id
    )
  order by ac.serial
  limit 1
  for update skip locked;

  if v_copy_id is null then
    raise exception 'No copies left';
  end if;

  -- Выдаём ownership
  insert into public.copy_ownership (
    copy_id,
    owner_user_id,
    acquired_at
  )
  values (
    v_copy_id,
    v_order.user_id,
    now()
  );

  -- Пишем transaction
  insert into public.transactions (
    copy_id,
    from_user_id,
    to_user_id,
    price,
    currency,
    type,
    created_at
  )
  values (
    v_copy_id,
    null,
    v_order.user_id,
    v_order.amount,
    v_order.currency,
    'primary',
    now()
  )
  returning id into v_transaction_id;

  -- Закрываем payment_order
  update public.payment_orders
  set
    status = 'fulfilled',
    copy_id = v_copy_id,
    transaction_id = v_transaction_id,
    fulfilled_at = now()
  where id = v_order.id;

  return query
  select
    v_order.id,
    v_copy_id,
    v_serial,
    v_transaction_id,
    'fulfilled'::text;
end;
$$;


ALTER FUNCTION "public"."fulfill_payment_order"("p_order_id" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."album_copies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "album_id" "uuid" NOT NULL,
    "serial" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."album_copies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."albums" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "cover_image_url" "text",
    "artist_name" "text",
    "price" numeric,
    "release_year" integer,
    "gallery_description" "text",
    "video_embed_url" "text",
    "background_color" "text",
    CONSTRAINT "albums_background_color_check" CHECK ((("background_color" IS NULL) OR ("background_color" ~ '^#([A-Fa-f0-9]{6})$'::"text"))),
    CONSTRAINT "albums_release_year_check" CHECK ((("release_year" IS NULL) OR (("release_year" >= 1900) AND ("release_year" <= 2100))))
);


ALTER TABLE "public"."albums" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."art_containers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "album_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "track_id" "uuid" DEFAULT "gen_random_uuid"(),
    "type" "text" NOT NULL,
    "content_url" "text" NOT NULL,
    "meta" "jsonb",
    "order" bigint
);


ALTER TABLE "public"."art_containers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."copy_ownership" (
    "copy_id" "uuid" NOT NULL,
    "owner_user_id" "uuid" NOT NULL,
    "acquired_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."copy_ownership" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "album_id" "uuid" NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "currency" "text" DEFAULT 'RUB'::"text" NOT NULL,
    "provider" "text" NOT NULL,
    "provider_payment_id" "text",
    "provider_order_id" "text",
    "status" "text" DEFAULT 'created'::"text" NOT NULL,
    "copy_id" "uuid",
    "transaction_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "paid_at" timestamp with time zone,
    "fulfilled_at" timestamp with time zone,
    "failed_at" timestamp with time zone,
    "canceled_at" timestamp with time zone,
    CONSTRAINT "payment_orders_provider_check" CHECK (("provider" = 'tbank'::"text")),
    CONSTRAINT "payment_orders_status_check" CHECK (("status" = ANY (ARRAY['created'::"text", 'payment_pending'::"text", 'paid'::"text", 'fulfilled'::"text", 'failed'::"text", 'canceled'::"text"])))
);


ALTER TABLE "public"."payment_orders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."purchases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "album_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_identifier" "uuid" NOT NULL,
    "nft_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."purchases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."track_previews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "track_id" "uuid" NOT NULL,
    "preview_kind" "text" NOT NULL,
    "content_url" "text" NOT NULL,
    "preview_order" integer DEFAULT 1 NOT NULL,
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "track_previews_preview_kind_check" CHECK (("preview_kind" = ANY (ARRAY['blurred_image'::"text", 'video_still'::"text", 'blurred_video'::"text"])))
);


ALTER TABLE "public"."track_previews" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tracks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "album_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text",
    "audio_url" "text",
    "track_number" bigint NOT NULL,
    "duration_seconds" integer
);


ALTER TABLE "public"."tracks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "copy_id" "uuid" NOT NULL,
    "from_user_id" "uuid",
    "to_user_id" "uuid" NOT NULL,
    "price" numeric(12,2),
    "currency" "text",
    "type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "transactions_type_check" CHECK (("type" = ANY (ARRAY['primary'::"text", 'resale'::"text"])))
);


ALTER TABLE "public"."transactions" OWNER TO "postgres";


ALTER TABLE ONLY "public"."albums"
    ADD CONSTRAINT "Albums_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tracks"
    ADD CONSTRAINT "Tracks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."album_copies"
    ADD CONSTRAINT "album_copies_album_serial_unique" UNIQUE ("album_id", "serial");



ALTER TABLE ONLY "public"."album_copies"
    ADD CONSTRAINT "album_copies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."art_containers"
    ADD CONSTRAINT "art_containers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."copy_ownership"
    ADD CONSTRAINT "copy_ownership_pkey" PRIMARY KEY ("copy_id");



ALTER TABLE ONLY "public"."payment_orders"
    ADD CONSTRAINT "payment_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."track_previews"
    ADD CONSTRAINT "track_previews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_pkey" PRIMARY KEY ("id");



CREATE INDEX "album_copies_album_id_idx" ON "public"."album_copies" USING "btree" ("album_id");



CREATE INDEX "copy_ownership_owner_user_id_idx" ON "public"."copy_ownership" USING "btree" ("owner_user_id");



CREATE INDEX "payment_orders_album_id_idx" ON "public"."payment_orders" USING "btree" ("album_id");



CREATE UNIQUE INDEX "payment_orders_provider_order_id_uidx" ON "public"."payment_orders" USING "btree" ("provider", "provider_order_id");



CREATE INDEX "payment_orders_provider_payment_id_idx" ON "public"."payment_orders" USING "btree" ("provider_payment_id");



CREATE INDEX "payment_orders_status_idx" ON "public"."payment_orders" USING "btree" ("status");



CREATE INDEX "payment_orders_user_id_idx" ON "public"."payment_orders" USING "btree" ("user_id");



CREATE INDEX "track_previews_kind_idx" ON "public"."track_previews" USING "btree" ("preview_kind");



CREATE INDEX "track_previews_order_idx" ON "public"."track_previews" USING "btree" ("track_id", "preview_order");



CREATE INDEX "track_previews_track_id_idx" ON "public"."track_previews" USING "btree" ("track_id");



CREATE INDEX "transactions_copy_id_idx" ON "public"."transactions" USING "btree" ("copy_id");



CREATE INDEX "transactions_to_user_id_idx" ON "public"."transactions" USING "btree" ("to_user_id");



ALTER TABLE ONLY "public"."tracks"
    ADD CONSTRAINT "Tracks_album_id_fkey" FOREIGN KEY ("album_id") REFERENCES "public"."albums"("id");



ALTER TABLE ONLY "public"."album_copies"
    ADD CONSTRAINT "album_copies_album_id_fkey" FOREIGN KEY ("album_id") REFERENCES "public"."albums"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."art_containers"
    ADD CONSTRAINT "art_containers_album_id_fkey" FOREIGN KEY ("album_id") REFERENCES "public"."albums"("id");



ALTER TABLE ONLY "public"."art_containers"
    ADD CONSTRAINT "art_containers_track_id_fkey" FOREIGN KEY ("track_id") REFERENCES "public"."tracks"("id");



ALTER TABLE ONLY "public"."copy_ownership"
    ADD CONSTRAINT "copy_ownership_copy_id_fkey" FOREIGN KEY ("copy_id") REFERENCES "public"."album_copies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."copy_ownership"
    ADD CONSTRAINT "copy_ownership_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payment_orders"
    ADD CONSTRAINT "payment_orders_album_id_fkey" FOREIGN KEY ("album_id") REFERENCES "public"."albums"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."payment_orders"
    ADD CONSTRAINT "payment_orders_copy_id_fkey" FOREIGN KEY ("copy_id") REFERENCES "public"."album_copies"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."payment_orders"
    ADD CONSTRAINT "payment_orders_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "public"."transactions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."payment_orders"
    ADD CONSTRAINT "payment_orders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."purchases"
    ADD CONSTRAINT "purchases_album_id_fkey" FOREIGN KEY ("album_id") REFERENCES "public"."albums"("id");



ALTER TABLE ONLY "public"."track_previews"
    ADD CONSTRAINT "track_previews_track_id_fkey" FOREIGN KEY ("track_id") REFERENCES "public"."tracks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_copy_id_fkey" FOREIGN KEY ("copy_id") REFERENCES "public"."album_copies"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_from_user_id_fkey" FOREIGN KEY ("from_user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_to_user_id_fkey" FOREIGN KEY ("to_user_id") REFERENCES "auth"."users"("id") ON DELETE RESTRICT;



ALTER TABLE "public"."album_copies" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "album_copies_select_authenticated" ON "public"."album_copies" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."albums" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "albums_select_public" ON "public"."albums" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."art_containers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "art_containers_select_public" ON "public"."art_containers" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."copy_ownership" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "copy_ownership_select_own" ON "public"."copy_ownership" FOR SELECT TO "authenticated" USING (("owner_user_id" = "auth"."uid"()));



CREATE POLICY "delete_own_purchases" ON "public"."purchases" FOR DELETE USING (("auth"."uid"() = "user_identifier"));



CREATE POLICY "insert_own_purchases" ON "public"."purchases" FOR INSERT WITH CHECK (("auth"."uid"() = "user_identifier"));



ALTER TABLE "public"."payment_orders" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "payment_orders_insert_own" ON "public"."payment_orders" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "payment_orders_select_own" ON "public"."payment_orders" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."purchases" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "select_own_purchases" ON "public"."purchases" FOR SELECT USING (("auth"."uid"() = "user_identifier"));



ALTER TABLE "public"."track_previews" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "track_previews_select_public" ON "public"."track_previews" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."tracks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tracks_select_public" ON "public"."tracks" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."transactions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "transactions_select_related" ON "public"."transactions" FOR SELECT TO "authenticated" USING ((("to_user_id" = "auth"."uid"()) OR ("from_user_id" = "auth"."uid"())));



CREATE POLICY "update_own_purchases" ON "public"."purchases" FOR UPDATE USING (("auth"."uid"() = "user_identifier")) WITH CHECK (("auth"."uid"() = "user_identifier"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."claim_album_copy"("p_album_id" "uuid", "p_price" numeric, "p_currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."claim_album_copy"("p_album_id" "uuid", "p_price" numeric, "p_currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_album_copy"("p_album_id" "uuid", "p_price" numeric, "p_currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."claim_album_copy_for_user"("p_album_id" "uuid", "p_user_id" "uuid", "p_price" numeric, "p_currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."claim_album_copy_for_user"("p_album_id" "uuid", "p_user_id" "uuid", "p_price" numeric, "p_currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_album_copy_for_user"("p_album_id" "uuid", "p_user_id" "uuid", "p_price" numeric, "p_currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."fulfill_payment_order"("p_order_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."fulfill_payment_order"("p_order_id" "uuid") TO "service_role";


















GRANT ALL ON TABLE "public"."album_copies" TO "anon";
GRANT ALL ON TABLE "public"."album_copies" TO "authenticated";
GRANT ALL ON TABLE "public"."album_copies" TO "service_role";



GRANT ALL ON TABLE "public"."albums" TO "anon";
GRANT ALL ON TABLE "public"."albums" TO "authenticated";
GRANT ALL ON TABLE "public"."albums" TO "service_role";



GRANT ALL ON TABLE "public"."art_containers" TO "anon";
GRANT ALL ON TABLE "public"."art_containers" TO "authenticated";
GRANT ALL ON TABLE "public"."art_containers" TO "service_role";



GRANT ALL ON TABLE "public"."copy_ownership" TO "anon";
GRANT ALL ON TABLE "public"."copy_ownership" TO "authenticated";
GRANT ALL ON TABLE "public"."copy_ownership" TO "service_role";



GRANT ALL ON TABLE "public"."payment_orders" TO "anon";
GRANT ALL ON TABLE "public"."payment_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_orders" TO "service_role";



GRANT ALL ON TABLE "public"."purchases" TO "anon";
GRANT ALL ON TABLE "public"."purchases" TO "authenticated";
GRANT ALL ON TABLE "public"."purchases" TO "service_role";



GRANT ALL ON TABLE "public"."track_previews" TO "anon";
GRANT ALL ON TABLE "public"."track_previews" TO "authenticated";
GRANT ALL ON TABLE "public"."track_previews" TO "service_role";



GRANT ALL ON TABLE "public"."tracks" TO "anon";
GRANT ALL ON TABLE "public"."tracks" TO "authenticated";
GRANT ALL ON TABLE "public"."tracks" TO "service_role";



GRANT ALL ON TABLE "public"."transactions" TO "anon";
GRANT ALL ON TABLE "public"."transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."transactions" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































