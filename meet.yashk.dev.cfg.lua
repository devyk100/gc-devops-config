plugin_paths = { "/usr/share/jitsi-meet/prosody-plugins/" }

-- domain mapper options, must at least have domain base set to use the mapper
muc_mapper_domain_base = "meet.yashk.dev";

external_service_secret = "HRlQRvnFExtI6Dit";
external_services = {
     { type = "stun", host = "meet.yashk.dev", port = 3478 },
     { type = "turn", host = "meet.yashk.dev", port = 3478, transport = "udp", secret = true, ttl = 86400, algorithm = >     { type = "turns", host = "meet.yashk.dev", port = 5349, transport = "tcp", secret = true, ttl = 86400, algorithm =>};

cross_domain_bosh = false;
consider_bosh_secure = true;
-- https_ports = { }; -- Remove this line to prevent listening on port 5284

-- by default prosody 0.12 sends cors headers, if you want to disable it uncomment the following (the config is availab>--http_cors_override = {
--    bosh = {
--        enabled = false;
--    };
--    websocket = {
--        enabled = false;
--    };
--}
-- https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.0g&guideline=5.4
ssl = {
    protocol = "tlsv1_2+";
    ciphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM->}

unlimited_jids = {
    "focus@auth.meet.yashk.dev",
    "jvb@auth.meet.yashk.dev"
}

VirtualHost "meet.yashk.dev"
    authentication = "allow_all" -- do not delete me
    -- Properties below are modified by jitsi-meet-tokens package config
    -- and authentication above is switched to "token"
    app_id="meet.yashk.dev"
    app_secret="123"
   -- allow_empty_token = false;
    -- Assign this host a certificate for TLS, otherwise it would use the one
    -- set in the global section (if any).
    -- Note that old-style SSL on port 5223 only supports one certificate, and will always
    -- use the global one.
    ssl = {
        key = "/etc/prosody/certs/meet.yashk.dev.key";
        certificate = "/etc/prosody/certs/meet.yashk.dev.crt";
    }
    av_moderation_component = "avmoderation.meet.yashk.dev"
    speakerstats_component = "speakerstats.meet.yashk.dev"
    end_conference_component = "endconference.meet.yashk.dev"
    -- we need bosh
    modules_enabled = {
        "bosh";
        "ping"; -- Enable mod_ping
        "speakerstats";
        "external_services";
        "conference_duration";
        "end_conference";
        "muc_lobby_rooms";
        "muc_breakout_rooms";
        "av_moderation";
        "room_metadata";
--      "token_verification";
        "reservations";
    }
    reservations_api_prefix = "https://a88yce22q3.execute-api.ap-south-1.amazonaws.com/Prod"
    c2s_require_encryption = false
     reservations_enable_lobby_support = true
    lobby_muc = "lobby.meet.yashk.dev"
    breakout_rooms_muc = "breakout.meet.yashk.dev"
    room_metadata_component = "metadata.meet.yashk.dev"
    main_muc = "conference.meet.yashk.dev"
    reservations_enable_password_support = true
    -- muc_lobby_whitelist = { "recorder.meet.yashk.dev" } -- Here we can whitelist jibri to enter lobby enabled rooms

VirtualHost "guest.meet.yashk.dev"
    authentication = "anonymous"
    c2s_require_encryption = false

Component "conference.meet.yashk.dev" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_hide_all";
        "muc_meeting_id";
        "muc_domain_mapper";
        "polls";
        "token_verification";
        "muc_rate_limit";
        "muc_password_whitelist";
    }
    admins = { "focus@auth.meet.yashk.dev" }
    muc_password_whitelist = {
        "focus@auth.meet.yashk.dev"
    }
    muc_room_locking = false
    muc_room_default_public_jids = true

Component "breakout.meet.yashk.dev" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_hide_all";
        "muc_meeting_id";
        "muc_domain_mapper";
        "muc_rate_limit";
        "polls";
    }
    admins = { "focus@auth.meet.yashk.dev" }
    muc_room_locking = false
    muc_room_default_public_jids = true

-- internal muc component
Component "internal.auth.meet.yashk.dev" "muc"
    storage = "memory"
    modules_enabled = {
        "muc_hide_all";
        "ping";
    }
    admins = { "focus@auth.meet.yashk.dev", "jvb@auth.meet.yashk.dev" }
    muc_room_locking = false
    muc_room_default_public_jids = true

VirtualHost "auth.meet.yashk.dev"
    ssl = {
        key = "/etc/prosody/certs/auth.meet.yashk.dev.key";
        certificate = "/etc/prosody/certs/auth.meet.yashk.dev.crt";
    }
    modules_enabled = {
        "limits_exception";
        "smacks";
    }
    authentication = "internal_hashed"
    smacks_hibernation_time = 15;

-- Proxy to jicofo's user JID, so that it doesn't have to register as a component.
Component "focus.meet.yashk.dev" "client_proxy"
    target_address = "focus@auth.meet.yashk.dev"

Component "speakerstats.meet.yashk.dev" "speakerstats_component"
    muc_component = "conference.meet.yashk.dev"

Component "endconference.meet.yashk.dev" "end_conference"
    muc_component = "conference.meet.yashk.dev"

Component "avmoderation.meet.yashk.dev" "av_moderation_component"
    muc_component = "conference.meet.yashk.dev"

Component "lobby.meet.yashk.dev" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true
    modules_enabled = {
  "muc_hide_all";
        "muc_rate_limit";
        "polls";
    }

Component "metadata.meet.yashk.dev" "room_metadata_component"
    muc_component = "conference.meet.yashk.dev"
    breakout_rooms_component = "breakout.meet.yashk.dev"
