module discord

import time
import x.json2
import net.urllib

pub type GuildFeature = string

pub struct PartialGuild {
pub:
	id                         Snowflake
	name                       string
	icon                       ?string
	owner                      bool
	permissions                Permissions
	features                   []GuildFeature
	approximate_member_count   ?int
	approximate_presence_count ?int
}

pub fn PartialGuild.parse(j json2.Any) !PartialGuild {
	match j {
		map[string]json2.Any {
			icon := j['icon']!
			return PartialGuild{
				id: Snowflake.parse(j['id']!)!
				name: j['name']! as string
				icon: if icon is string {
					?string(icon)
				} else {
					none
				}
				owner: j['owner']! as bool
				permissions: Permissions.parse(j['permissions']!)!
				features: (j['features']! as []json2.Any).map(GuildFeature(it as string))
				approximate_member_count: if i := j['approximate_member_count'] {
					?int(i as int)
				} else {
					none
				}
				approximate_presence_count: if i := j['approximate_presence_count'] {
					?int(i as int)
				} else {
					none
				}
			}
		}
		else {
			return error('expected partial guild to be object, got ${j.type_name()}')
		}
	}
}

@[params]
pub struct FetchMyGuildsParams {
pub:
	before      ?Snowflake
	after       ?Snowflake
	limit       ?int
	with_counts ?bool
}

pub fn (c Client) fetch_my_guilds(params FetchMyGuildsParams) ![]PartialGuild {
	mut vs := urllib.new_values()
	if before := params.before {
		vs.add('before', before.build())
	}
	if after := params.after {
		vs.add('after', after.build())
	}
	if limit := params.limit {
		vs.add('limit', limit.str())
	}
	if with_counts := params.with_counts {
		vs.add('with_counts', with_counts.str())
	}
	tmp1 := vs.encode()
	tmp2 := if tmp1 == '' { '' } else { '?${tmp1}' }
	return (json2.raw_decode(c.request(.get, '/users/@me/guilds${tmp2}')!.body)! as []json2.Any).map(PartialGuild.parse(it)!)
}

pub enum VerificationLevel {
	// unrestricted
	none_
	// must have verified email on account
	low
	// must be registered on Discord for longer than 5 minutes
	medium
	// must be a member of the server for longer than 10 minutes
	high
	// must have a verified phone number
	very_high
}

pub enum MessageNotificationsLevel {
	// members will receive notifications for all messages by default
	all_messages
	// members will receive notifications only for messages that @mention them by default
	only_mentions
}

pub enum ExplicitContentFilterLevel {
	// media content will not be scanned
	disabled
	// media content sent by members without roles will be scanned
	members_without_roles
	// media content sent by all members will be scanned
	all_members
}

pub enum MFALevel {
	// guild has no MFA/2FA requirement for moderation actions
	none_
	// guild has a 2FA requirement for moderation actions
	elevated
}

pub struct RoleTags {
pub:
	// the id of the bot this role belongs to
	bot_id ?Snowflake
	// the id of the integration this role belongs to
	integration_id ?Snowflake
	// whether this is the guild's Booster role
	premium_subscriber bool
	// the id of this role's subscription sku and listing
	subscription_listing_id ?Snowflake
	// whether this role is available for purchase
	available_for_purchase bool
	// whether this role is a guild's linked role
	guild_connections bool
}

pub fn RoleTags.parse(j json2.Any) !RoleTags {
	match j {
		map[string]json2.Any {
			return RoleTags{
				bot_id: if s := j['bot_id'] {
					Snowflake.parse(s)!
				} else {
					none
				}
				integration_id: if s := j['integration_id'] {
					Snowflake.parse(s)!
				} else {
					none
				}
				premium_subscriber: 'premium_subscriber' in j
				subscription_listing_id: if s := j['subscription_listing_id'] {
					Snowflake.parse(s)!
				} else {
					none
				}
				available_for_purchase: 'available_for_purchase' in j
				guild_connections: 'guild_connections' in j
			}
		}
		else {
			return error('expected role tags to be object, got ${j.type_name()}')
		}
	}
}

@[flag]
pub enum RoleFlags {
	// role can be selected by members in an onboarding prompt
	in_prompt
}

pub struct Role {
pub:
	// role id
	id Snowflake
	// role name
	name string
	// integer representation of hexadecimal color code
	color int
	// if this role is pinned in the user listing
	hoist bool
	// role icon hash
	icon ?string
	// role unicode emoji
	unicode_emoji ?string
	// position of this role
	position int
	// permission bit set
	permissions Permissions
	// whether this role is managed by an integrations
	managed bool
	// whether this role is mentionable
	mentionable bool
	// the tags this role has
	tags ?RoleTags
	// role flags combined as a bitfield
	flags RoleFlags
}

pub fn Role.parse(j json2.Any) !Role {
	match j {
		map[string]json2.Any {
			return Role{
				id: Snowflake.parse(j['id']!)!
				name: j['name']! as string
				color: int(j['color']! as i64)
				hoist: j['hoist']! as bool
				icon: if s := j['icon'] {
					if s is string {
						?string(s)
					} else {
						none
					}
				} else {
					none
				}
				unicode_emoji: if s := j['unicode_emoji'] {
					if s is string {
						?string(s)
					} else {
						none
					}
				} else {
					none
				}
				position: int(j['position']! as i64)
				permissions: Permissions.parse(j['permissions']!)!
				managed: j['managed']! as bool
				mentionable: j['mentionable']! as bool
				tags: if o := j['tags'] {
					?RoleTags(RoleTags.parse(o)!)
				} else {
					none
				}
				flags: unsafe { RoleFlags(j['flags']! as i64) }
			}
		}
		else {
			return error('expected role to be object, got ${j.type_name()}')
		}
	}
}

@[flag]
pub enum SystemChannelFlags {
	// Suppress member join notifications
	suppress_join_notifications
	// Suppress server boost notifications
	suppress_premium_subscriptions
	// Suppress server setup tips
	suppress_guild_reminder_notifications
	// Hide member join sticker reply buttons
	suppress_join_notification_replies
	// Suppress role subscription purchase and renewal notifications
	suppress_role_subscription_purchase_notifications
	// Hide role subscription sticker reply buttons
	suppress_role_subscription_purchase_notifications_replies
}

pub enum PremiumTier {
	// guild has not unlocked any Server Boost perks
	none_
	// guild has unlocked Server Boost level 1 perks
	tier_1
	// guild has unlocked Server Boost level 2 perks
	tier_2
	// guild has unlocked Server Boost level 3 perks
	tier_3
}

pub enum NSFWLevel {
	default
	explicit
	safe
	age_restricted
}

pub struct WelcomeChannel {
pub:
	// the channel's id
	channel_id ?Snowflake
	// the description shown for the channel
	description string
	// the emoji id, if the emoji is custom
	emoji_id ?Snowflake
	// the emoji name if custom, the unicode character if standard, or `none` if no emoji is set
	emoji_name ?string
}

pub fn WelcomeChannel.parse(j json2.Any) !WelcomeChannel {
	match j {
		map[string]json2.Any {
			emoji_id := j['emoji_id']!
			emoji_name := j['emoji_name']!
			return WelcomeChannel{
				channel_id: Snowflake.parse(j['channel_id']!)!
				description: j['description']! as string
				emoji_id: if emoji_id !is json2.Null {
					?Snowflake(Snowflake.parse(emoji_id)!)
				} else {
					none
				}
				emoji_name: if emoji_name !is json2.Null {
					?string(emoji_name as string)
				} else {
					none
				}
			}
		}
		else {
			return error('expected welcome channel to be object, got ${j.type_name()}')
		}
	}
}

pub struct WelcomeScreen {
pub:
	// the server description shown in the welcome screen
	description ?string
	// the channels shown in the welcome screen, up to 5
	welcome_channels []WelcomeChannel
}

pub fn WelcomeScreen.parse(j json2.Any) !WelcomeScreen {
	match j {
		map[string]json2.Any {
			description := j['description']!
			return WelcomeScreen{
				description: if description is string {
					?string(description)
				} else {
					none
				}
				welcome_channels: (j['welcome_channels']! as []json2.Any).map(WelcomeChannel.parse(it)!)
			}
		}
		else {
			return error('expected welcome screen to be object, got ${j.type_name()}')
		}
	}
}

pub struct Guild {
pub:
	// guild id
	id Snowflake
	// guild name (2-100 characterrs, excluding trailing and leading whitespace)
	name string
	// icon hash
	icon ?string
	// icon hash, returned when in the template object
	icon_hash ?string
	// splash hash
	splash ?string
	// discovery splash hash; only present for guilds with the "DISCOVERABLE" feature
	discovery_splash ?string
	// id of owner
	owner_id Snowflake
	// id of afk channel
	afk_channel_id ?Snowflake
	// afk timeout
	afk_timeout time.Duration
	// true if the server widget is enabled
	widget_enabled ?bool
	// the channel id that the widget will generate an invite to, or `none` if set to no invite
	widget_channel_id ?Snowflake
	// verification level required for the guild
	verification_level VerificationLevel
	// default message notifications level
	default_message_notifications MessageNotificationsLevel
	// explicit content filter level
	explicit_content_filter ExplicitContentFilterLevel
	// roles in the guild
	roles []Role
	// custom guild emojis
	emojis []Emoji
	// enabled guild features
	features []GuildFeature
	// required MFA level for the guild
	mfa_level MFALevel
	// application id of the guild creator if it is bot-created
	application_id ?Snowflake
	// the id of the channel where guild notices such as welcome messages and boost events are posted
	system_channel_id ?Snowflake
	// system channel flags
	system_channel_flags SystemChannelFlags
	// the id of the channel where Community guilds can display rules and/or guidelines
	rules_channel_id ?Snowflake
	// the maximum number of presences for the guild (`none` is always returned, apart from largest of guilds)
	max_presences ?int
	// the maximum number of members for the guild
	max_members ?int
	// the vanity url code for the guild
	vanity_url_code ?string
	// the description of a guild
	description ?string
	// banner hash
	banner ?string
	// premium tier (Server Boost level)
	premium_tier PremiumTier
	// the number of boosts this guild currently has
	premium_subscription_count ?int
	// the preferred locale of a Community guild; used in server discovery and notices from Discord, and sent in interactions; defaults to "en-US"
	preferred_locale string
	// the id of the channel where admins and moderators of Community guilds receive notices from Discord
	public_updates_channel_id ?Snowflake
	// the maximum amount of users in a video channel
	max_video_channel_users ?int
	// // the maximum amount of users in a stage video channel
	max_stage_video_channel_users ?int
	// approximate number of members in this guild, returned from the `GET /guilds/<id>` and `/users/@me/guilds` endpoints when `with_counts` is `true`
	approximate_member_count ?int
	// approximate number of non-offline members in this guild, returned from the `GET /guilds/<id>` and `/users/@me/guilds` endpoints when `with_counts` is `true`
	approximate_presence_count ?int
	// the welcome screen of a Community guild, shown to new members, returned in an Invite's guild object
	welcome_screen ?WelcomeScreen
	// guild NSFW level
	nsfw_level NSFWLevel
	// custom guild stickers
	stickers []Sticker
	// whether the guild has the boost progress bar enabled
	premium_progress_bar_enabled bool
	// the id of the channel where admins and moderators of Community guilds receive safety alerts from Discord
	safety_alerts_channel_id ?Snowflake
}

pub fn Guild.parse(j json2.Any) !Guild {
	match j {
		map[string]json2.Any {
			icon := j['icon']!
			icon_hash := j['icon_hash']!
			splash := j['splash']!
			discovery_splash := j['discovery_splash']!
			afk_channel_id := j['afk_channel_id']!
			application_id := j['application_id']!
			system_channel_id := j['system_channel_id']!
			rules_channel_id := j['rules_channel_id']!
			vanity_url_code := j['vanity_url_code']!
			description := j['description']!
			banner := j['banner']!
			public_updates_channel_id := j['public_updates_channel_id']!
			safety_alerts_channel_id := j['safety_alerts_channel_id']!
			return Guild{
				id: Snowflake.parse(j['id']!)!
				name: j['name']! as string
				icon: if icon is string {
					?string(icon)
				} else {
					none
				}
				icon_hash: if icon_hash is string {
					?string(icon_hash)
				} else {
					none
				}
				splash: if splash is string {
					?string(splash)
				} else {
					none
				}
				discovery_splash: if discovery_splash is string {
					?string(discovery_splash)
				} else {
					none
				}
				owner_id: Snowflake.parse(j['owner_id']!)!
				afk_channel_id: if afk_channel_id !is json2.Null {
					?Snowflake(Snowflake.parse(afk_channel_id)!)
				} else {
					none
				}
				afk_timeout: j['afk_timeout']! as i64 * time.second
				widget_enabled: if b := j['widget_enabled'] {
					?bool(b as bool)
				} else {
					none
				}
				widget_channel_id: if s := j['widget_channel_id'] {
					if s !is json2.Null {
						Snowflake.parse(s)!
					} else {
						none
					}
				} else {
					none
				}
				verification_level: unsafe { VerificationLevel(j['verification_level']! as i64) }
				explicit_content_filter: unsafe { ExplicitContentFilterLevel(j['explicit_content_filter']! as i64) }
				roles: (j['roles']! as []json2.Any).map(Role.parse(it)!)
				emojis: (j['emojis']! as []json2.Any).map(Emoji.parse(it)!)
				features: (j['features']! as []json2.Any).map(GuildFeature(it as string))
				mfa_level: unsafe { MFALevel(j['mfa_level']! as i64) }
				application_id: if application_id !is json2.Null {
					?Snowflake(Snowflake.parse(application_id)!)
				} else {
					none
				}
				system_channel_id: if system_channel_id !is json2.Null {
					?Snowflake(Snowflake.parse(system_channel_id)!)
				} else {
					none
				}
				system_channel_flags: unsafe { SystemChannelFlags(j['system_channel_flags']! as i64) }
				rules_channel_id: if rules_channel_id !is json2.Null {
					?Snowflake(Snowflake.parse(rules_channel_id)!)
				} else {
					none
				}
				max_presences: if i := j['max_presences'] {
					if i is int {
						?int(i)
					} else {
						none
					}
				} else {
					none
				}
				max_members: if i := j['max_members'] {
					if i is int {
						?int(i)
					} else {
						none
					}
				} else {
					none
				}
				vanity_url_code: if vanity_url_code !is json2.Null {
					?string(vanity_url_code as string)
				} else {
					none
				}
				description: if description !is json2.Null {
					?string(description as string)
				} else {
					none
				}
				banner: if banner !is json2.Null {
					?string(banner as string)
				} else {
					none
				}
				premium_tier: unsafe { PremiumTier(j['premium_tier']! as i64) }
				premium_subscription_count: if i := j['premium_subscription_count'] {
					?int(i as i64)
				} else {
					none
				}
				preferred_locale: j['preferred_locale']! as string
				public_updates_channel_id: if public_updates_channel_id !is json2.Null {
					?Snowflake(Snowflake.parse(public_updates_channel_id)!)
				} else {
					none
				}
				max_video_channel_users: if i := j['max_video_channel_users'] {
					?int(i as i64)
				} else {
					none
				}
				max_stage_video_channel_users: if i := j['max_stage_video_channel_users'] {
					?int(i as i64)
				} else {
					none
				}
				approximate_member_count: if i := j['approximate_member_count'] {
					?int(i as i64)
				} else {
					none
				}
				approximate_presence_count: if i := j['approximate_presence_count'] {
					?int(i as i64)
				} else {
					none
				}
				welcome_screen: if o := j['welcome_screen'] {
					?WelcomeScreen(WelcomeScreen.parse(o)!)
				} else {
					none
				}
				nsfw_level: unsafe { NSFWLevel(j['nsfw_level']! as i64) }
				stickers: ((j['stickers'] or { []json2.Any{} }) as []json2.Any).map(Sticker.parse(it)!)
				premium_progress_bar_enabled: j['premium_progress_bar_enabled']! as bool
				safety_alerts_channel_id: if safety_alerts_channel_id !is json2.Null {
					?Snowflake(Snowflake.parse(safety_alerts_channel_id)!)
				} else {
					none
				}
			}
		}
		else {
			return error('expected guild to be object, got ${j.type_name()}')
		}
	}
}

pub fn (c Client) fetch_guild(guild_id Snowflake) !Guild {
	return Guild.parse(json2.raw_decode(c.request(.get, '/guilds/${urllib.path_escape(guild_id.build())}')!.body)!)!
}

@[flag]
pub enum GuildMemberFlags {
	// Member has left and rejoined the guild
	did_rejoin
	// Member has completed onboarding
	completed_onboarding
	// Member is exempt from guild verification requirements
	bypasses_verification
	// Member has started onboarding
	started_onboarding
}

pub struct GuildMember {
pub:
	// the user this guild member represents
	user ?User
	// this user's guild nickname
	nick ?string
	// the member's guild avatar hash
	avatar ?string
	// array of role object ids
	roles []Snowflake
	// when the user joined the guild
	joined_at time.Time
	// when the user started boosting the guild
	premium_since ?time.Time
	// whether the user is deafened in voice channels
	deaf bool
	// whether the user is muted in voice channels
	mute bool
	// guild member flags represented as a bit set, defaults to 0
	flags GuildMemberFlags
	// whether the user has not yet passed the guild's Membership Screening requirements
	pending ?bool
	// total permissions of the member in the channel, including overwrites, returned when in the interaction object
	permissions ?Permissions
	// when the user's timeout will expire and the user will be able to communicate in the guild again, null or a time in the past if the user is not timed out
	communication_disabled_until ?time.Time
}

pub fn GuildMember.parse(j json2.Any) !GuildMember {
	match j {
		map[string]json2.Any {
			return GuildMember{
				user: if o := j['user'] {
					?User(User.parse(o)!)
				} else {
					none
				}
				nick: if s := j['nick'] {
					if s !is json2.Null {
						?string(s as string)
					} else {
						none
					}
				} else {
					none
				}
				avatar: if s := j['avatar'] {
					if s !is json2.Null {
						?string(s as string)
					} else {
						none
					}
				} else {
					none
				}
				roles: (j['roles']! as []json2.Any).map(Snowflake.parse(it)!)
				joined_at: time.parse_iso8601(j['joined_at']! as string)!
				premium_since: if s := j['premium_since'] {
					if s !is json2.Null {
						?time.Time(time.parse_iso8601(s as string)!)
					} else {
						none
					}
				} else {
					none
				}
				deaf: j['deaf']! as bool
				mute: j['mute']! as bool
				flags: unsafe { GuildMemberFlags(j['flags']! as i64) }
				pending: if b := j['pending'] {
					?bool(b as bool)
				} else {
					none
				}
				permissions: if s := j['permissions'] {
					?Permissions(Permissions.parse(s)!)
				} else {
					none
				}
				communication_disabled_until: if s := j['communication_disabled_until'] {
					if s !is json2.Null {
						?time.Time(time.parse_iso8601(s as string)!)
					} else {
						none
					}
				} else {
					none
				}
			}
		}
		else {
			return error('expected guild member to be object, got ${j.type_name()}')
		}
	}
}