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

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: battle_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.battle_invites (
    id bigint NOT NULL,
    battle_id bigint,
    player_id bigint,
    confirmed boolean DEFAULT false,
    survived boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: battle_invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.battle_invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: battle_invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.battle_invites_id_seq OWNED BY public.battle_invites.id;


--
-- Name: battles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.battles (
    id bigint NOT NULL,
    room_id bigint,
    challenge_id character varying,
    challenge_url character varying,
    challenge_name character varying,
    challenge_language character varying,
    challenge_rank integer,
    challenge_description text,
    max_survivors integer,
    time_limit integer,
    end_time timestamp without time zone,
    start_time timestamp without time zone,
    winner_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: battles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.battles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: battles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.battles_id_seq OWNED BY public.battles.id;


--
-- Name: chats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chats (
    id bigint NOT NULL,
    name character varying,
    room_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: chats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chats_id_seq OWNED BY public.chats.id;


--
-- Name: completed_challenges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.completed_challenges (
    id bigint NOT NULL,
    user_id bigint,
    challenge_id character varying,
    challenge_name character varying,
    challenge_slug character varying,
    completed_at timestamp without time zone,
    completed_languages character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: completed_challenges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.completed_challenges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: completed_challenges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.completed_challenges_id_seq OWNED BY public.completed_challenges.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    user_id bigint,
    chat_id bigint,
    content character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: room_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_users (
    id bigint NOT NULL,
    room_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: room_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.room_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.room_users_id_seq OWNED BY public.room_users.id;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id bigint NOT NULL,
    name character varying,
    moderator_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rooms_id_seq OWNED BY public.rooms.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying,
    username character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying,
    admin boolean DEFAULT false,
    codewars_honor integer,
    codewars_clan character varying,
    codewars_leaderboard_position integer,
    codewars_overall_rank integer,
    codewars_overall_score integer,
    last_fetched_at timestamp without time zone,
    authentication_token character varying(30)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: battle_invites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battle_invites ALTER COLUMN id SET DEFAULT nextval('public.battle_invites_id_seq'::regclass);


--
-- Name: battles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battles ALTER COLUMN id SET DEFAULT nextval('public.battles_id_seq'::regclass);


--
-- Name: chats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chats ALTER COLUMN id SET DEFAULT nextval('public.chats_id_seq'::regclass);


--
-- Name: completed_challenges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.completed_challenges ALTER COLUMN id SET DEFAULT nextval('public.completed_challenges_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: room_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_users ALTER COLUMN id SET DEFAULT nextval('public.room_users_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms ALTER COLUMN id SET DEFAULT nextval('public.rooms_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: battle_invites battle_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battle_invites
    ADD CONSTRAINT battle_invites_pkey PRIMARY KEY (id);


--
-- Name: battles battles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battles
    ADD CONSTRAINT battles_pkey PRIMARY KEY (id);


--
-- Name: chats chats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT chats_pkey PRIMARY KEY (id);


--
-- Name: completed_challenges completed_challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.completed_challenges
    ADD CONSTRAINT completed_challenges_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: room_users room_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_users
    ADD CONSTRAINT room_users_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_battle_invites_on_battle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_battle_invites_on_battle_id ON public.battle_invites USING btree (battle_id);


--
-- Name: index_battle_invites_on_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_battle_invites_on_player_id ON public.battle_invites USING btree (player_id);


--
-- Name: index_battles_on_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_battles_on_room_id ON public.battles USING btree (room_id);


--
-- Name: index_battles_on_winner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_battles_on_winner_id ON public.battles USING btree (winner_id);


--
-- Name: index_chats_on_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chats_on_room_id ON public.chats USING btree (room_id);


--
-- Name: index_completed_challenges_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_completed_challenges_on_user_id ON public.completed_challenges USING btree (user_id);


--
-- Name: index_messages_on_chat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_chat_id ON public.messages USING btree (chat_id);


--
-- Name: index_messages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_user_id ON public.messages USING btree (user_id);


--
-- Name: index_room_users_on_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_room_users_on_room_id ON public.room_users USING btree (room_id);


--
-- Name: index_room_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_room_users_on_user_id ON public.room_users USING btree (user_id);


--
-- Name: index_rooms_on_moderator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rooms_on_moderator_id ON public.rooms USING btree (moderator_id);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON public.users USING btree (authentication_token);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: messages fk_rails_0f670de7ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_0f670de7ba FOREIGN KEY (chat_id) REFERENCES public.chats(id);


--
-- Name: messages fk_rails_273a25a7a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_273a25a7a6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: rooms fk_rails_5844594c86; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT fk_rails_5844594c86 FOREIGN KEY (moderator_id) REFERENCES public.users(id);


--
-- Name: battle_invites fk_rails_58c0bafa42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battle_invites
    ADD CONSTRAINT fk_rails_58c0bafa42 FOREIGN KEY (battle_id) REFERENCES public.battles(id);


--
-- Name: battles fk_rails_7c4a09af7f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battles
    ADD CONSTRAINT fk_rails_7c4a09af7f FOREIGN KEY (winner_id) REFERENCES public.users(id);


--
-- Name: room_users fk_rails_99ebf589ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_users
    ADD CONSTRAINT fk_rails_99ebf589ee FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: battle_invites fk_rails_a129ef714a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battle_invites
    ADD CONSTRAINT fk_rails_a129ef714a FOREIGN KEY (player_id) REFERENCES public.users(id);


--
-- Name: completed_challenges fk_rails_afcfea9859; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.completed_challenges
    ADD CONSTRAINT fk_rails_afcfea9859 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: battles fk_rails_d02cbefcdf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.battles
    ADD CONSTRAINT fk_rails_d02cbefcdf FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: chats fk_rails_d05dcb5af1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT fk_rails_d05dcb5af1 FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: room_users fk_rails_f4e2e6f10e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_users
    ADD CONSTRAINT fk_rails_f4e2e6f10e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20190709143512'),
('20190709152004'),
('20190709152102'),
('20190709152326'),
('20190709153630'),
('20190710035639'),
('20190710043750'),
('20190712122253'),
('20190718010634'),
('20190718011449');


