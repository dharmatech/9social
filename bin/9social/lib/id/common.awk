# Shared 9social ID validation helpers.
#
# This file is loaded by executable awk scripts with:
#   #!/bin/awk -f /bin/9social/lib/id/common.awk -f
#
# It intentionally contains only functions.

# Return true if s contains only lowercase hexadecimal digits.
function is_hex(s)
{
	return s ~ /^[0-9a-f]+$/
}

# Return true if s is a canonical lowercase UUID: 8-4-4-4-12.
function is_uuid(s,    p)
{
	if(split(s, p, "-") != 5)
		return 0
	return \
		length(p[1]) ==  8 && is_hex(p[1]) && \
		length(p[2]) ==  4 && is_hex(p[2]) && \
		length(p[3]) ==  4 && is_hex(p[3]) && \
		length(p[4]) ==  4 && is_hex(p[4]) && \
		length(p[5]) == 12 && is_hex(p[5])
}

# Return true if s is a canonical lowercase UUIDv4.
function is_uuid_v4(s,    p)
{
	return is_uuid(s, p) && substr(p[3], 1, 1) == "4" && substr(p[4], 1, 1) ~ /^[89ab]$/
}

# Return true if s is 9social:user:<uuid>.
function is_user_id(s,    p)
{
	if(split(s, p, ":") != 3)
		return 0
	return p[1] == "9social" && p[2] == "user" && is_uuid(p[3])
}

# Return true if s is 9social:post:<user-uuid>:<post-uuid>.
function is_post_id(s,    p)
{
	if(split(s, p, ":") != 4)
		return 0
	return p[1] == "9social" && p[2] == "post" && is_uuid(p[3]) && is_uuid(p[4])
}

# Extract the UUID from 9social:user:<uuid>.
# Callers should call this only after is_user_id(s) succeeds.
function user_id_uuid(s,    p)
{
	split(s, p, ":")
	return p[3]
}
