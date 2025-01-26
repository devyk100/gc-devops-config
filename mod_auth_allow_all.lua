-- Import required modules
local http = require "socket.http";
local ltn12 = require "ltn12";
local json = require "util.json";

-- Define the authentication provider
local provider = {};

-- Log module initialization
prosody.log("info", "mod_auth_allow_all: Initializing");

-- Helper function to URL-encode a string
local function url_encode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n");
        str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
            return string.format("%%%02X", string.byte(c));
        end);
        str = string.gsub(str, " ", "+");
    end
    return str;
end

-- Always allow user creation (not really used, but required by Prosody)
function provider.create_user(username, password)
    return true;
end

-- Confirm that the user exists only if the username is "user"
function provider.user_exists(username)
    return username == "user";
end

-- Always allow password changes (not really used, but required by Prosody)
function provider.set_password(username, password)
    return true;
end

-- Allow authentication only if the username is "user"
function provider.test_password(username, password)
    -- Prepare the request body in x-www-form-urlencoded format
    local request_body = string.format(
        "email=%s&password=%s&mail_owner=%s",
        url_encode(username),
        url_encode(password),
        url_encode(username)
    );

   -- Make a POST request to the external API
    local url = "https://a88yce22q3.execute-api.ap-south-1.amazonaws.com/Prod/conf-auth";
    local response_body = {};
    local res, code, headers, status = http.request({
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["Content-Length"] = #request_body
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body)
    });

    -- Check if the request was successful
    if code ~= 200 then
        prosody.log("error", "mod_auth_allow_all: API request failed with code " .. code);
        return false;
    end

    -- Parse the response
    local response = json.decode(table.concat(response_body));
    if response and response.Ok then
        prosody.log("info", "mod_auth_allow_all: Authentication successful for user " .. username);
        return true;
else
        prosody.log("warn", "mod_auth_allow_all: Authentication failed for user " .. username);
        return false;
    end
end

-- Required for SASL authentication
function provider.get_sasl_handler()
    local new_sasl = require "util.sasl".new;
    return new_sasl(module.host, {
        plain_test = function(sasl, username, password) -- luacheck: ignore 212/sasl
            return provider.test_password(username, password), true;
        end
    });
end

-- Register the authentication provider
module:provides("auth", provider);
