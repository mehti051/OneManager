local db = dofile 'lib/redis.lua'
local tdcli = dofile 'bot/utlis.lua'
local serp = require 'serpent'.block
local JSON = dofile 'lib/JSON.lua'
local _config = dofile 'data/td_config.lua'
local _color = require 'term.colors'
require('./bot/utlis')
function delete_msg(chatid,mid)
  tdcli_function ({
  ID="DeleteMessages", 
  chat_id_=chatid, 
  message_ids_=mid
  },
  dl_cb, nil)
end

local function hfunc (arg,data)
print(data.total_count_)
for k,v in pairs(data.messages_) do
tdcli.deleteMessages(v.chat_id_,{[0] = v.id_})
end
end


local function chat_type(data)
local msg = data.message_
if msg.chat_id_:match('^-100(%d+)') then 
chat_type = 'supergroups'
elseif msg.chat_id_:match('^(%d+)') then
chat_type = 'private'
end
return chat_type
end
function sleep(time)
os.execute("sleep " .. tonumber(time)) 
end
 function vardump(data)
  print(serp(data, {comment=false}))
end

local function tdump(data)
  return serp(data, {comment=false})
end

local function reload()
loadfile("./bot/bot.lua")()
end

local function write_var(var, file_name)
	file = io.open(file_name, "w")
	if not file then
		return false
	end
	file:write(tdump(var))
	file:close()
end

local function print_res(arg, data)
  write_var(data, arg.file_path)
end

---- Sudo ----

local function sudo(data)
local msg = data.message_
local user_id = msg.sender_user_id_
local chat_id = msg.chat_id_
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

local function sudo2(user_id)
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

---- Admin ----

local function admin(data)
local msg = data.message_
local user_id = msg.sender_user_id_
local chat_id = msg.chat_id_
local admins = db:sismember('max:adminss',user_id)
if admins then
return true
end
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

local function admin2(user_id)
local admins = db:sismember('max:adminss',user_id)
if admins then
return true
end
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

---- Owner ----

local function owner(data)
local msg = data.message_
local user_id = msg.sender_user_id_
local chat_id = msg.chat_id_
local admins = db:sismember('max:adminss',user_id)
if admins then
return true
end
local owners = db:sismember('gp:owners:'..chat_id,user_id)
if owners then
return true
end
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

local function owner2(chat_id, user_id)
local admins = db:sismember('max:adminss',user_id)
if admins then
return true
end
local owners = db:sismember('gp:owners:'..chat_id,user_id)
if owners then
return true
end
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

----- Mod -----

local function mod(data)
local msg = data.message_
local user_id = msg.sender_user_id_
local chat_id = msg.chat_id_
local admins = db:sismember('max:adminss',user_id)
if admins then
return true
end
local mod = db:sismember('gp:mods:'..chat_id,user_id)
if mod then
return true
end
local owners = db:sismember('gp:owners:'..chat_id,user_id)
if owners then
return true
end
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

local function mod2(chat_id, user_id)
local admins = db:sismember('max:adminss',user_id)
if admins then
return true
end
local mod = db:sismember('gp:mods:'..chat_id,user_id)
if mod then
return true
end
local owners = db:sismember('gp:owners:'..chat_id,user_id)
if owners then
return true
end
for k,user in pairs(_config.sudo_users) do
if user == user_id then
return true
end
end
end

----------------End------------------
---- CallBack ----
local function delUser(chat_id, user_id)
  tdcli.changeChatMemberStatus(chat_id, user_id, 'Kicked')
end

---- Mute Reply ----
local function mute_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
--[[local lang_hash_max = 'group:'..msg.chat_id_..':lang'
local lang = db:get(lang_hash_max)]]
if mod2(ch, user) then
--if lang then
--tdcli.sendMessage(ch, msg_id, 1, "شما نمیتوانید مدیر ,ادمین , سودو رو خفه کنید...!")
--else
tdcli.sendMessage(ch, msg_id, 1, "*Error*\n_You Can't Mute Mods/Owners/Admins...!_", 1, 'md')
--end
else
--if lang then
db:sadd('mutes:'..ch,user)
--tdcli.sendMessage(ch, msg_id, 1, "شخص مورد نظر خفه شد")
--else
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n_User ["..user.."] Added To Mute List...!_", 1, 'md')
print(user)
end
end
--end
local function mute_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
if mod2(chat_id, result.id_) then
tdcli.sendMessage(chat_id,0, 1, "*Error*\n_You Can't Mute Mods/Owners/Admins...!_", 1, 'md')
else
db:sadd('mutes:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Added To Mute List..!_',0,'md')
db:del('chatid')
end
end

local function unmute_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:srem('mutes:'..ch,user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n_User ["..user.."] Removed From Mute List...!_", 1, 'md')
print(user)
end

local function unmute_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:srem('mutes:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Removed From Mute List..!_',0,'md')
db:del('chatid')
end

---- Id Reply ----

local function id_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
tdcli.sendMessage(ch, msg_id, 1, "*> Chat Id :* ["..ch:gsub('-100','').."]\n*> User Id :* ["..user.."]", 1, 'md')
print(user)
end

---- Delete Messages Reply ----

local function del_reply(extra, result, success)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
--tdcli.deleteMessagesFromUser(ch,user)
print(user)
end

---- Gban Reply ----

local function gban_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
if admin2(user) then
tdcli.sendMessage(ch, msg_id, 1, "*Error*\n_You Can't GBan /Admins...!_", 1, 'md')
else
db:sadd('gbans:user',user)
tdcli.changeChatMemberStatus(ch, user, 'Kicked')
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Globally Banned..!*", 1, 'md')
print(user)
end
end

local function gban_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
if mod2(chat_id, result.id_) then
tdcli.sendMessage(chat_id,0, 1, "*Error*\n_You Can't Gban Admins...!_", 1, 'md')
else
db:sadd('gbans:user:'..chat_id, result.id_)
tdcli.changeChatMemberStatus(chat_id, result.id_, 'Kicked')
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Globally Banned..!_',0,'md')
db:del('chatid')
end
end

---- UnGan Reply ----

local function ungban_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:srem('gbans:user',user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Unglobally Banned..!*", 1, 'md')
print(user)
end

local function ungban_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:srem('gbans:user:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Un Globally Banned..!_',0,'md')
db:del('chatid')
end

---- Gban Reply ----

local function ban_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
if mod2(ch, user) then
tdcli.sendMessage(ch, msg_id, 1, "*Error*\n_You Can't Ban Mods/Owners/Admins...!_", 1, 'md')
else
db:sadd('bans:gp:'..ch,user)
tdcli.changeChatMemberStatus(ch, user, 'Kicked')
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Banned..!*", 1, 'md')
print(user)
end
end

local function ban_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
if mod2(chat_id, result.id_) then
tdcli.sendMessage(chat_id,0, 1, "*Error*\n_You Can't Ban Mods/Owners/Admins...!_", 1, 'md')
else
db:sadd('bans:gp:'..chat_id, result.id_)
tdcli.changeChatMemberStatus(chat_id, result.id_, 'Kicked')
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Banned..!_',0,'md')
db:del('chatid')
end
end

---- UnBan Reply ----

local function unban_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:srem('bans:gp:'..ch,user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *UnBanned..!*", 1, 'md')
print(user)
end

local function unban_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:srem('bans:gp:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Unbanned..!_',0,'md')
db:del('chatid')
end

---- DeAdmin Reply ----

local function deadmin_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:srem('max:adminss',user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Demoted From Global Admin..!*", 1, 'md')
print(user)
end

local function deadmin_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:srem('max:adminss', result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Demoted From Globally Admin.!_',0,'md')
db:del('chatid')
end

---- SetAdmin Reply ----

local function setadmin_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:sadd('max:adminss',user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Promoted To Global Admin..!*", 1, 'md')
print(user)
end

local function setadmin_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:sadd('max:adminss', result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Promoted To Globally Admin..!_',0,'md')
db:del('chatid')
end

---- SetOwner Reply ----

local function setowner_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:sadd('gp:owners:'..ch,user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Promoted To Group Owner..!*", 1, 'md')
print(user)
end

local function setowner_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:sadd('gp:owners:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Promoted To Group Owner..!_',0,'md')
db:del('chatid')
end

---- DeOwner Reply ----

local function deowner_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:srem('gp:owners:'..ch,user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Demoted From Group Owner..!*", 1, 'md')
print(user)
end

local function deowner_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:srem('gp:owners:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Demoted From Group Owner..!_',0,'md')
db:del('chatid')
end

---- Promote Reply ----

local function promote_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:sadd('gp:mods:'..ch,user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Promoted..!*", 1, 'md')
print(user)
end
local function clean_bots(extra,result)
for bk=0 ,#result.members_ do
local uid = result.members_[bk].user_id_
tdcli.changeChatMemberStatus(extra.gid, uid, 'Kicked')
end
end
local function promote_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:sadd('gp:mods:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..'] Promoteded..!_',0,'md')
db:del('chatid')
end

---- Promote Reply ----

local function demote_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
db:srem('gp:mods:'..ch,user)
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n*User* _["..user.."]_ *Demoted..!*", 1, 'md')
print(user)
end

local function demote_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
db:srem('gp:mods:'..chat_id, result.id_)
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..']  Demoted..!_',0,'md')
db:del('chatid')
end

-------- Kick -------

local function kick_reply(extra, result, success)
t = vardump(result)
local msg_id = result.id_
local user = result.sender_user_id_
local ch = result.chat_id_
if mod2(ch, user) then
tdcli.sendMessage(ch, msg_id, 1, "*Error*\n_You Can't Kick Mods/Owners/Admins...!_", 1, 'md')
else
tdcli.changeChatMemberStatus(ch, user, 'Kicked')
tdcli.sendMessage(ch, msg_id, 1, "*Done*\n_User ["..user.."] Kicked..!_", 1, 'md')
print(user)
end
end

local function kick_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
if mod2(chat_id, result.id_) then
tdcli.sendMessage(chat_id,0, 1, "*Error*\n_You Can't Kick Mods/Owners/Admins...!_", 1, 'md')
else
tdcli.changeChatMemberStatus(chat_id, result.id_, 'Kicked')
tdcli.sendMessage(chat_id,0,1,'*Done*\n_User ['..result.id_..']  Kicked..!_',0,'md')
db:del('chatid')
end
end

-------- UserName CallBack ---------
local function info_username(extra, result, success)
vardump(result)
chat_id = db:get('chatid')
local function dl_photo(arg,data) 
tdcli.sendPhoto(chat_id, 0, 0, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_,result.id_..'\n'..result.type_.user_.first_name_) 
end
  tdcli_function ({ID = "GetUserProfilePhotos",user_id_ = result.id_,offset_ = 0,limit_ = 100000}, dl_photo, nil)
db:del('chatid')
end
local function info_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, info_username, extra)
end
local function setowner_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, setowner_username, extra)
end
local function deowner_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, deowner_username, extra)
end
local function gban_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, gban_username, extra)
end
local function ungban_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, ungban_username, extra)
end
local function promote_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, promote_username, extra)
end
local function demote_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, demote_username, extra)
end
local function ban_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, ban_username, extra)
end
local function unban_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, unban_username, extra)
end
local function mute_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, mute_username, extra)
end
local function unmute_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, unmute_username, extra)
end
local function kick_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, kick_username, extra)
end
-------- GetMessage -------

local function getMessage(chat_id, message_id,callback)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, callback, nil)
end
local function trigger_anti_spam(msg, chat_id, user_id,action)  --#NFS
tdcli.sendMessage(chat_id,0,0,'دادش داری اشتباه میزنی',1,'md')
if action == 'kick' then
	 --deleteMessagesFromUser(chat_id, user_id, cb, cmd)
	 deldelUser(chat_id, user_id)
	 elseif action == 'ban' then
     --deleteMessagesFromUser(chat_id, user_id, cb, cmd)
end
	 msg = nil
	 return
  end
function tdcli_update_callback(data)
--------- Welcome Setp --------
if data.ID == 'UpdateChatTopMessage' then
if not data.top_message_ then
return
end
if type(data.top_message_.reply_markup_) ~= 'boolean' then
print('key')
if db:get('keyboard:Lock:'..data.top_message_.chat_id_) == 'Lock' then
local gid =  data.top_message_.chat_id_
tdcli.deleteMessages(data.chat_id_,{[0] = data.top_message_.message_id_})
end
end
if data.top_message_.via_bot_user_id_ ~= 0 then
print('bot')
if db:get('inline:Lock:'..data.top_message_.chat_id_) == 'Lock' then
local gid =  data.top_message_.chat_id_
print('inline')

tdcli.deleteMessages(data.chat_id_,{[0] = data.top_message_.message_id_})
end
end

--[[if data.top_message_.content_ and data.top_message_.content_.ID ==  or data.top_message_.content_.ID == 'MessageChatAddMembers' then
local gid =  data.top_message_.chat_id_
local uid = data.top_message_.sender_user_id_
local name = info.members_[0].first_name_
local username = info.members_[0].username_
local wlc_msg = db:hget('wlc',gid) or 'hi'
local welcome = wlc_msg:gsub('{username}',username) or "None" 
local welcome = welcome:gsub('{name}',name) or "None"
tdcli.sendMessage(gid,0, 1,welcome, 1, 'md')
end]]
if data.message_ and data.message_.content_.members_ and data.message_.content_.members_[0].type_.ID == 'UserTypeBot' then --IS bot
local gid = tonumber(data.message_.chat_id_)
local uid = data.message_.sender_user_id_
local aid = data.message_.content_.members_[0].id_
local id = data.message_.id_
if db:get('bot:Lock:'..data.chat_id_) == 'Lock' then
tdcli.changeChatMemberStatus(gid, aid, 'Kicked')
tdcli.changeChatMemberStatus(gid, uid, 'Kicked')
end
end
local msg = data.top_message_
local chat = data.chat_id_
if msg.content_.ID == 'MessageChatAddMembers' or msg.content_.ID == 'MessageChatJoinByLink' then 
local info = data.top_message_.content_
local name = info.members_[0].first_name_
local username = info.members_[0].username_
local chat = data.toage_.chat_id_
local wlc_msg = db:hget('wlc',chat)
local welcome = wlc_msg:gsub('{username}',username) or "None"
local welcome = welcome:gsub('{name}',name) or "None"
tdcli.sendMessage(chat,0, 1,welcome, 1, 'md')
elseif msg.content_.ID == 'MessagePinMessage' then
if db:get('pin:Lock:'..data.top_message_.chat_id_) == 'Lock' and db:get('pin:post:'..data.top_message_.chat_id_) then
if msg.sender_user_id_ ~= 191512505 then
tdcli.unpinChannelMessage(data.top_message_.chat_id_)
tdcli.sendMessage(data.top_message_.chat_id_,0, 1,'Just Reply The Message And Send (pin)...!', 1, 'md')
tdcli.pinChannelMessage(data.top_message_.chat_id_,db:get('pin:post:'..data.top_message_.chat_id_),0)
else
db:set('pin:post:'..data.top_message_.chat_id_,data.top_message_.content_.message_id_)
tdcli.sendMessage(data.top_message_.chat_id_,0, 1,'pin shood ba robot', 1, 'md')
end
elseif not db:get('pin:post:'..data.top_message_.chat_id_) then
db:set('pin:post:'..data.top_message_.chat_id_,data.top_message_.content_.message_id_)
tdcli.sendMessage(data.top_message_.chat_id_,0, 1,'Pin msg has been seted', 1, 'md')
end
end
end

--------- End Welcome Step ---------

if data.ID == 'UpdateMessageEdited' then
if db:get('edit:Show:'..data.chat_id_) == 'Show' then
text = db:hget('msgs:'..data.chat_id_,data.message_id_)
tdcli.sendMessage(data.chat_id_,data.message_id_,0,'خخخ چرا ادیت کردی پیامتو😄\nدیدم گفتی:\n'..text,1,'md')
db:hset('msgs:'..data.chat_id_,data.message_id_,data.new_content_.text_)
--db:hdel('msgs:'..data.sender_user_id,data.message_id_) 
end
if db:get('edit:Lock:'..data.chat_id_) == 'Lock' then
tdcli.deleteMessages(data.chat_id_,{[0] = data.message_id_})
end
end
------- Start Project -------

if (data.ID == "UpdateNewMessage") then
local msg = data.message_
local group = db:sismember('gpo',msg.chat_id_)
local ch = msg.chat_id_
local user_id = msg.sender_user_id_
if not group and not admin(data) then
return false
end
local floods = db:get('flood:Lock:'..ch) or  'off'
local max_msg = db:get('flood-spam:'..ch) or 20
local max_time = db:get('flood-time:'..ch) or 20
if floods == 'Lock' and  not mod(data) then --anti flood #behrad
 local post_count = 'floodc:' .. msg.sender_user_id_ .. ':' .. msg.chat_id_
 db:incr(post_count)
 local post_count = 'user:' .. msg.sender_user_id_ .. ':floodc'
 local msgs = tonumber(db:get(post_count) or 0)
 if tonumber(msgs) > tonumber(max_msg) then
 trigger_anti_spam(msg, msg.chat_id_, msg.sender_user_id_,'kick')
 end
 db:setex(post_count, tonumber(max_time), tonumber(msgs)+1)
end
local edit_id = data.text_ or 'nil' --bug #behrad
--------Bot Settings-------
if msg.forward_info_ and msg.chat_id_:match("-1001087436653") then
vardump(data)
tdcli.importChatInviteLink(msg.content_.text_)
end
if msg.forward_info_ and db:get('fwd:Lock:'..msg.chat_id_) == 'Lock' and not mod(data) then
tdcli.deleteMessages(msg.chat_id_, {[0] = msg.id_})
end
if msg.forward_info_ and db:get('userid:'..msg.sender_user_id_) then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, 'Post Views => `'..msg.views_..'`', 1, 'md')
db:del('userid:'..msg.sender_user_id_)
end
if msg.content_.voice_ or msg.content_.audio_ or msg.content_.video_ or msg.content_.photo_ or msg.content_.animation_ or msg.content_.document_  or msg.content_.contact_ or msg.content_.sticker_ or msg.content_.text_ or msg.content_.location_ then
if db:get('user_id:'..msg.sender_user_id_) then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, 'File Caption => _['..msg.content_.caption_..']_', 1,'md')
db:del('user_id:'..msg.sender_user_id_)
end
if not mod(data) then
if msg.content_.photo_ and db:get('photo:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.contact_ and db:get('contact:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.audio_ and db:get('audio:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.location_ and db:get('location:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.video_ and db:get('video:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.animation_ and db:get('animation:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.sticker_ and db:get('sticker:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.document_ and db:get('document:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.location_ and db:get('location:Lock:'..msg.chat_id_) == 'Lock' then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if msg.content_.caption_  then
text_cheack = msg.content_.caption_
else 
text_cheack  = msg.content_.text_
end
if db:get('arabic:Lock:'..msg.chat_id_) == 'Lock' and text_cheack:match('[\216-\219][\128-\191]') then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if db:get('en:Lock:'..msg.chat_id_) == 'Lock' and text_cheack:lower():find('[a-z]') or text_cheack:lower():find('[A-Z]') then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if db:get('tag:Lock:'..msg.chat_id_) == 'Lock' and text_cheack:lower():find('#') then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end

if db:get('emoji:Lock:'..msg.chat_id_) == 'Lock' and text_cheack:lower():match("[😀😬😁😂😃😀😬😁😂😃😄😅😆😇😉😊🙂🙃☺️😋😌😍😘😗😙😚😜😝😛🤑🤓😎🤗😏😶😐😑😒🙄🤔😳😞😟😠😡😔😕🙁☹️😣😖😫😩😤😮😱😨😰😯😦😧😢😥😪😓😭😵😲🤐😷🤒🤕😴💤💩😈👿👹👺💀👻👽🤖😺😸😹😻😼😽👍👋🏻👏🏻👍🏻🙌🏻😾😿🙀👎🏻👊🏻✊🏻✌🏻👌🏻✋🏻👐🏻💪🏻🙏🏻☝🏻️👆🏻👇🏻👈🏻👉🏻🖕🏻🖐🏻🤘🏻🖖🏻✍🏻💅🏻👄👅👂🏻👃🏻👁👀👤👥🗣👶🏻👦🏻👧🏻👨🏻👩🏻👱🏻👴🏻👵🏻👲🏻👳🏻👮🏻👷🏻💂🏻🕵🎅🏻👼🏻👸🏻👰🏻🚶🏻🏃🏻💃🏻👯👫👬👭🙇🏻💁🏻🙅🏻🙆🏻🙋🏻🙎🏻🙍🏻💇🏻💆🏻💑👩‍❤️‍👩👨‍❤️‍👨💏👩‍❤️‍💋‍👩👨‍❤️‍💋‍👨👪👨‍👩‍👧👨‍👩‍👧‍👦👨‍👩‍👦‍👦👨‍👩‍👧‍👧👩‍👩‍👦👩‍👩‍👧👩‍👩‍👧‍👦👩‍👩‍👦‍👦👩‍👩‍👧‍👧👨‍👨‍👦👨‍👨‍👧👨‍👨‍👧‍👦👨‍👨‍👦‍👦👨‍👨‍👧‍👧👚👕👖👔👗👙👘💄💋👣👠👡👢👞👟👒🎩🎓👑⛑🎒💍🕶👓💼👜👛👝🌂🐶🐱🐭🐹🐰🐻🐼🐸🐽🐷🐮🦁🐯🐨🐙🐵🙈🙉🙊🐒🐔🐗🐺🐥🐣🐤🐦🐧🐴🦄🐝🐛🐌🐞🐜🐟🐠🐢🐍🦀🦂🕷🐡🐬🐳🐊🐋🐆🐅🐐🐘🐫🐪🐄🐂🐃🐏🐑🐎🐖🐀🐁🐓🐿🐇🐈🐩🐕🕊🦃🐾🐉🐲🌵🎄🌲🌳🎋🎍🍀☘🌿🌱🌴🍃🍂🍁🌾🌺🌻🌹🎃🌰🍄💐🌸🌼🌷🐚🕸🌎🌍🌏🌕🌖🌚🌔🌓🌒🌑🌘🌗🌝🌛🌜🌞🌙⭐️🌟💫✨☄☀️🌤⛅️🌥🔥⚡️🌩⛈🌧☁️🌦💥❄️🌨☃⛄️🌬💨🌊💦💧☔️☂🌫🌪🍏🍎🍐🍊🍋🍌🍉🍅🍍🍑🍒🍈🍓🍇🍆🌶🌽🍠🍯🍞🧀🌭🍟🍔🍳🍤🍖🍗🍕🍝🌮🌯🍜🍲🍥🍢🍘🍚🍙🍛🍱🍣🍡🍧🍨🍦🍰🎂🍮🍺🍪🍩🍿🍫🍭🍬🍻🍷🍸🍹🍾🍶🍵☕️🍼🍴🍽⚽️🏀🏈⚾️🎾🏐🏉🏑🏒🏸🏓🏌⛳️🎱🏏🎿⛷🏂⛸🏹🎣🚴🏻🏋🏻⛹🏻🛀🏻🏄🏻🏊🏻🚣🏻🚵🏻🏇🏻🕴🏆🎽🏅🎖🎪🎨🎭🎟🎫🏵🎗🎤🎧🎼🎹🎷🎺🎸🎸🎺🎷🎼🎹🎧🎤🎻🎬🎮👾🎯🎲🎰🎳🚗🚕🚙🚌🚎🏎🚓🏍🚜🚛🚚🚐🚒🚑🚲🚨🚔🚍🚘🚖🚡🚅🚄🚝🚋🚃🚟🚠🚈🚞🚂🚆🚇🚊🚉🛥⛵️🛬🛫✈️🛩🚁🚤⛴🛳🚀🛰💺⚓️🚢🏁🚥🚦🚏⛽️🚧🎡🎢🎠🏗🌁🗼🏭🗾🌋🗻🏔⛰🎑⛲️🏕⛺️🏞🛣🛤🌅🌄🌃🏙🌆🌇🏝🏖🏜🌉🌌🌠🎇🎆🌈🏘🏰🏯🏟🗽🏠🏡🏚🏢🏬🏣🏤🏥🏦🏨🕌⛪️🏛💒🏩🏫🏪🕍🕋⛩⌚️📱📲💻⌨🖥🖨💿💾💽🗜🕹🖲🖱📀📼📷📹📹🎥📽📻📺📠📟☎️📞🎞🎙🎚🎛⏱⏲⏰🕰🔦💡🔌🔋📡⌛️⏳🕯🗑🛢💸💵💴💶⚒🛠⛏🔩⚙⛓🔫☠🚬🛡⚔🗡🔪💣💷💰💳💎⚖🔧🔨⚰⚱🏺🔮📿💈⚗🏷🌡💉💊🕳🔬🔭🔖🚽🚿🛁🔑🗝🛋⛱🗺🖼🛎🚪🛏🛌🗿🛍🎈🎏🎀🎁🎊📩✉️🏮🎌🎐🎎🎉📨📧💌📮📪📫📬📃📜📤📥📯📦📭📑📊📈📉📄📅📆🗒📋🗄🗳🗃📇🗓📁📂🗂🗞📰📓📕📖📚📒📔📙📘📗🔗📎🖇✂️📐📏📌🔓🔒🔐🏴🏳🚩📍🔏🖊🖋✒️📝✏️🖍🔎🖌❤️💛💚💙💜❣❣💝💘💖💗💞💕💟☮✝☪🕉☸✡♈️♏️♎️☸🛐♍️♌️☦♋️☯♊️🕎♉️🔯♐️♑️♒️♓️🆔⚛🈳🈚️🈶📳📴☣☢🈹🈸🈺🈷✴️🆚🉑💮🅰🈲🈵🈴㊗️㊙️🉐🅱🆎🆑🅾🆘⛔️📛🚫❌⭕️💢♨️🚷🚯❓❕❗️📵🔞🚱🚳❔‼️⁉️🔅💯🔆🔱🈯️♻️🔰🚸⚠️〽️⚜💹❇️✳️❎✅💠🌀🛃🛂🈂🏧Ⓜ️🌐➿🛄🛅♿️🚭🚾🅿️🚰📶🎦🚮🚻🚼🚺🚹🈁🆖🆗🆙🚻🆒🚮🆕🎦🆓📶0⃣1⃣2⃣3⃣4⃣5⃣6⃣⏸▶️🔢🔟9⃣8⃣7⃣⏯⏹⏺⏭⏮⏩⏪⏫🔽🔼◀️🔂🔁🔀⏬➡️⬅️⬆️⬇️↗️↘️🔡🔤ℹ️*⃣#⃣⤴️↙️↖️🔄↪️↩️↩️✔️➰〰🎵🔣🔠🔃➕➖✖️➗💲💱🔝🔛🔙™®©🔜☑️🔘⚪️⚫️🔴🔵▫️▪️🔺🔷🔶🔹🔸⬛️⬜️🔻◼️◻️◾️◽️📣🔇🔉🔳🔲📢🔔🔕🃏🀄️♠️♣️💬🗯👁‍🗨💭🎴♦️♦️♥️🕐🕑🕒🕓🕔🕕🕖🕤🕟🕞🕗🕜🕝🕥🕦🇦🇫🇦🇱🇩🇿🇩🇿🇦🇸🇦🇩🇦🇴🇦🇮🇦🇶🇦🇮🇦🇬🇦🇷🇧🇭🇧🇸🇦🇿🇦🇹🇦🇺🇦🇼🇦🇲🇧🇩🇧🇧🇧🇪🇧🇾🇧🇿🇧🇯🇧🇲🇻🇬🇮🇴🇧🇷🇧🇦🇧🇹🇧🇳🇧🇬🇧🇫🇧🇮🇨🇲🇨🇦🇧🇮🇨🇳🇨🇽🇨🇴🇰🇲🇨🇬🇨🇩🇨🇩🇨🇾🇨🇼🇨🇺🇨🇮🇨🇷🇨🇰🇸🇻🇬🇶🇪🇹🇪🇺🇫🇰🇪🇬🇨🇿🇫🇴🇫🇯🇫🇷🇵🇫🇹🇫🇹🇫🇬🇳🇬🇬🇬🇵🇬🇩🇬🇱🇬🇱🇬🇦🇬🇦🇬🇲🇬🇭🇬🇳🇮🇸🇭🇰🇭🇳🇬🇼🇮🇳🇮🇩🇮🇷🇮🇶🇮🇪🇮🇲🇮🇲🇮🇱🇰🇪🇰🇿🇯🇴🇯🇪🇯🇵🇯🇲🇮🇹🇰🇮🇽🇰🇰🇼🇰🇬🇱🇦🇱🇻🇱🇧🇲🇴🇱🇺🇱🇹🇱🇮🇱🇾🇱🇷🇱🇸🇲🇭🇲🇶🇲🇷🇲🇺🇾🇹🇲🇽🇫🇲🇲🇿🇲🇦🇲🇸🇲🇪🇲🇳🇲🇨🇲🇩🇲🇲🇳🇦🇳🇷🇳🇵🇳🇨🇳🇨🇳🇿🇲🇵🇰🇵🇳🇫🇳🇺🇳🇬🇳🇪🇳🇮🇳🇴🇴🇲🇵🇰🇵🇼🇵🇦🇵🇸🇵🇬🇸🇲🇼🇸🇵🇷🇵🇱🇵🇱🇵🇱🇷🇺🇵🇳🇷🇴🇵🇪🇷🇪🇵🇪🇶🇦🇴🇲🇵🇪🇵🇾🇸🇹🇸🇦🇸🇳🇸🇨🇸🇱🇸🇬🇿🇦🇸🇧🇸🇽🇰🇷🇸🇸🇪🇸🇧🇱🇸🇭🇰🇳🇸🇪🇸🇷🇸🇩🇱🇨🇨🇭🇸🇾🇹🇼🇹🇯🇹🇿🇹🇭🇹🇱🇹🇲🇹🇷🇹🇳🇹🇹🇹🇴🇹🇰🇹🇬🇹🇨🇹🇨🇹🇻🇻🇮🇺🇬🇺🇬🇺🇦🇬🇧🇦🇪🇬🇧🇺🇸🇺🇸🇺🇾🇺🇿🇺🇿🇻🇺🇻🇦🇻🇪🇻🇪🇻🇳🇿🇼🇾🇪🇼🇫😄😅😆😇😉😊🙂🙃☺️😋😌😍😘😗😙😚😜😝😛🤑🤓😎🤗😏😶😐😑😒🙄🤔😳😞😟😠😡😔😕🙁☹️😣😖😫😩😤😮😱😨😰😯😦😧😢😥😪😓😭😵😲🤐😷🤒🤕😴💤💩😈👿👹👺💀👻👽🤖😺😸😹😻😼😽🙀😿😾🙌👏👋👍👎👊✊✌️👌✋👐💪🙏☝️👆👇👈👉🖕🖐🤘🖖✍💅👄👅👂👃👁👀👤👥🗣👶👦👧👨👩👱👴👵👲👳👮👷💂🕵🎅👼👸👰🚶🏃💃👯👫👬👭🙇💁🙅🙆🙋🙎🙍💇💆💑👩‍❤️‍👩👨‍❤️‍👨💏👩‍❤️‍💋‍👩👨‍❤️‍💋‍👨👪👨‍👩‍👧👨‍👩‍👧‍👦👨‍👩‍👦‍👦👨‍👩‍👧‍👧👩‍👩‍👦👩‍👩‍👧👩‍👩‍👧‍👦👩‍👩‍👦‍👦👩‍👩‍👧‍👧👨‍👨‍👦👨‍👨‍👧👨‍👨‍👧‍👦👨‍👨‍👦‍👦👨‍👨‍👧‍👧👨‍👨‍👧‍👧👚👕👖👔👗👙👘💄💋👣👠👡👢👞👟👒🎩🎓👑⛑🎒👝👛👜💼👓🕶💍🌂❤️💛💚💙💖💗💓💞💕❣💔💜💘💝]") then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
local mute = db:sismember('mutes:'..ch,user_id)
if mute then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
end
if db:get('muteall:'..msg.chat_id_) == 'Lock' then
tdcli.deleteMessages(msg.chat_id_, {[0] = msg.id_})
end
end
if msg.content_.text_ then
db:hset('msgs:'..msg.chat_id_,msg.id_,msg.content_.text_)
local text = msg.content_.text_:lower():gsub('^[#!/]','')
local link =  msg.content_.text_:match('(https?://telegram.me/joinchat/%S+)') or msg.content_.text_:match('(https?://t.me/joinchat/%S+)')
if link and tostring(db:get('link:wait:'..msg.chat_id_)) == tostring(msg.sender_user_id_) then
local link =  msg.content_.text_:match('(https?://telegram.me/joinchat/%S+)') or msg.content_.text_:match('(https?://t.me/joinchat/%S+)')
db:set('link:gp:'..msg.chat_id_,link)
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Done*\n_Link Has Been Set...!_', 1, 'md')
db:del('link:wait:'..msg.chat_id_)
end
if db:get('md:Lock:'..msg.chat_id_ ) == 'Lock' and msg.content_.entities_[0] then
if not mod(data) then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
end
local text_cheack = text_cheack or msg.content_.text_
local links = false
for k,v in pairs(msg.content_.entities_) do
if v.ID == "messageEntityTextUrl" or v.ID == "messageEntityUrl" then
links = true
end
end
if db:get('links:Lock:'..msg.chat_id_ ) == 'Lock' and links then
if not mod(data) then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
end
if msg.content_.ID == 'MessageText' and db:get('username:Lock:'..msg.chat_id_ ) == 'Lock' and not mod(data) and text_cheack:lower():match('@') then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})   
else 
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
if db:get('spam:Lock:'..msg.chat_id_) == 'Lock' and not mod(data) then
local chare = tonumber(db:get('chare:'..msg.chat_id_) or 0)
if string.len(msg.content_.text_) >= chare and not mod(data) then
if db:get('security:'..msg.chat_id_) == 'del' then
tdcli.deleteMessages(msg.chat_id_,{[0] = msg.id_})
else
tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
end
end
end
-----------Locals----------

local text = msg.content_.text_:lower():gsub('[#!/]','')
local chat_id = msg.chat_id_
local msg_id = msg.id_
local reply_msg = msg.reply_to_message_id_
local user_id = msg.sender_user_id_

------------BadWord-----------

local hash = db:smembers('badwords:'..chat_id)
if not mod(data) then
for k,v in pairs(hash) do
if msg.content_.text_:lower() == v or text:find(v) then
tdcli.deleteMessages(chat_id, {[0] = msg.id_})
end
end
end
if db:get('cmd:Lock:'..chat_id) == 'Lock' and not mod(data) then
return
end
--------Commands ------
if msg.content_.text_:match("^[!/#]getpro") then 
local matches = {
      msg.content_.text_:match("[!/#](getpro) (%d+)")
   }
if not matches[2] then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '/getpro 1-100', 1,'md')
else
local function dl_photo(arg,data) 
tdcli.sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_,''..msg.sender_user_id_..'') 
end
  tdcli_function ({ID = "GetUserProfilePhotos",user_id_ = msg.sender_user_id_,offset_ = matches[2],limit_ = 100000}, dl_photo, nil)
end
end
if text:lower() == "ping" then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, 'Ping...!', 1,'md')
elseif text:lower() == "set" and db:get('join:'..msg.sender_user_id_)then
db:sadd('gpo',msg.chat_id_)
db:setex('free:gp:'..chat_id,216000,216000)
tdcli.sendMessage(chat_id,msg.id_,0,'Done',0,'md')
db:del('join:'..msg.sender_user_id_)
db:sadd('gp:owners:'..chat_id,user_id)
elseif text:lower() == 'reload' and sudo(data) then
reload()
tdcli.sendMessage(chat_id,msg.id_,0,'Reloaded...!',0,'md')
elseif text:lower() == 'help' and mod(data) then
local text = 
  [[
💠*Help list :*
➖➖➖➖➖➖

🔐  برای دریافت راهنمای قفل ها :
🔒 !lockhelp


🔇 برای دریافت راهنمای میوت ها :
🔊 !mutehelp


⚄1�7 برای دریافت راهنمای مدیریت گروه :
🔧 !manghelp

➖➖➖➖➖➖
  ]]
    tdcli.sendMessage(msg.chat_id_,0,1,text,0,'md')
elseif text:lower() == 'lockhelp' and mod(data) then
  local text = 
  [[
🔐*Help LockList :*
➖➖➖➖➖➖

◾️قفل/بازکردن لینک :
▪️!lock/unlock *links*


◽️قفل/بازکردن ادیت :
▫️!lock/unlock *edit*


◾️قفل/بازکردن فوروارد :
▪️!lock/unlock *fwd*


◽️ قفل/بازکردن ریپلای :
▫️!lock/unlock *reply*


◾️ قفل/باز کردن فارسی/عربی :
▪️!lock/unlock *arabic*


◽️ قفل/باز کردن انگلیسی :
▫️!lock/unlock *english*


⬛️ قفل/باز کردن فلود :
▪️!lock/unlock *flood*


◽️ قفل/بازکردن خوش آمد گویی :
▫️!lock/unlock *welcome*

➖➖➖➖➖➖
  ]]
    tdcli.sendMessage(msg.chat_id_,0,1,text,0,'md')
  elseif text:lower() == 'mutehelp' and mod(data) then
  local text = 
  [[
🔇*Help MuteList :*
➖➖➖➖➖➖

◾️میوت/بازکردن چت :
▪️!mute/unmute *all*


◽️میوت/بازکردن عکس :
▫️!mute/unmute *photo*


◾️میوت/بازکردن مدیا :
▪️!mute/unmute *audio*


◽️میوت/بازکردن لوکیشن :
▫️!mute/unmute *location*


◾️میوت/بازکردن استیکر :
▪️!mute/unmute *sticker*


◽️میوت/بازکردن گیف :
▫️!mute/unmute *gif*


⬛️میوت/بازکردن فایل :
▪️!mute/unmute *document*


◽️میوت/بازکردن فیلم :
▫️!mute/unmute *video*

⬛️میوت/بازکردن شماره :
▪️!mute/unmute *contact*

➖➖➖➖➖➖
  ]]
  tdcli.sendMessage(msg.chat_id_,0,1,text,0,'md')
  elseif text:lower() == 'manghelp' and mod(data) then
  local text = 
  [[
⚄1�7*Help Management :*
➖➖➖➖➖➖

◾️برای حذف کردن فردی از گروه :
▪️!kick [UserName|reply]


◽️برای بن/آنبن کردن فردی از گروه :
▫️!ban/unban [UserName|reply]


◾️برای انتخاب/حذف مدیر :
▪️!promote/demote [UserName|reply]


◽️برای اضافه/حذف کردن کلمه برای فیلتر :
▫️!addword/remword [text]


◾️برای دیدن لیست کلمات فیلتر شده :
▪️!badwords


◽️برای دریافت تنظیمات :
▫️!settings


◾️برای سایلنت/آنسایلنت کردن فردی :
▪️!silent/unsilent


◽️برای دیدن لیست مدیران : 
▫️!modlist


◾️برای پین/آنپین کردن یک پیام :
▪️!pin/unpin [reply]


◽️برای دیدن بن لیست :
▫️!banlist


◾️برای دیدن ایدی عددی خود/دیگران :
▪️!id [reply]


◽️برای تغییر امنیت گروه به حذف پیام/حذف کاربر :
▫️!security [del|kick]


◾️برای تنطیم متن خوش آمد گویی :
▪️!setwelcome [text]

➖➖➖➖➖➖
  ]]
    tdcli.sendMessage(msg.chat_id_,0,1,text,0,'md')
elseif text:match('setwelcome (.*)') then
local wlc = text:match('setwelcome (.*)')
db:hset('wlc',chat_id, wlc)
tdcli.sendMessage(chat_id, msg_id, 0, '*Done*\n_Welcome Has Been Set..!_',1,'md')
elseif msg.content_.text_:match('info (.*)$') then
local matches = {
      msg.content_.text_:match("[!/#](info) (.*)")
   }
info_user(matches[2]:gsub('@',''))
db:set('chatid',chat_id)
elseif text:lower() == 'reload' and sudo(data) then
print(_color.green..'Done Bot Reloaded By => ['..user_id..']')
reload()
tdcli.sendMessage(msg.chat_id_,msg.id_,0,'Reloaded',0,'md')
elseif text:lower() == 'add' and admin(data) then
db:sadd('gpo', chat_id)
db:set('flood-spam:'..chat_id,10)
db:set('chare:'..chat_id, 500)
db:set('flood-time:'..chat_id,5)
tdcli.sendMessage(chat_id, msg_id , 1, '*Done*\n_Group Has Been Added To Group List..!_', 1, 'md')
elseif text:lower() == 'rem' and admin(data) then
db:srem('gpo', chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Done*\n_Group Has Been Removed From Group List..!_', 1, 'md')
elseif text:lower() == "id" then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*> Chat Id :* ["..chat_id:gsub('-100','').."]\n*> Your Id :* ["..user.."]", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_, id_reply,nil)
end
elseif text:lower() == 'pin' and mod(data) then
if msg.reply_to_message_id_ == 0 then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*What Should I Pin..?!*', 1,'md')
end
tdcli.pinChannelMessage(msg.chat_id_,msg.reply_to_message_id_,0)
elseif text:lower() == 'unpin' and mod(data)  then
tdcli.unpinChannelMessage(msg.chat_id_)
elseif text:lower():match('edit (.*)') and admin(data) then
local text2 = text:lower():match('edit (.*)')	
tdcli.editMessageText(msg.chat_id_,msg.reply_to_message_id_,nil,text2,1,'md')
elseif text:match('echo (.*)') then
local text2 = text:match('echo (.*)')	
tdcli.sendMessage(msg.chat_id_,msg.id_,1,text2,1,'md')
elseif text:lower() == 'views' then
db:set('userid:'..user_id, true)
tdcli.sendMessage(chat_id, msg_id , 1, '*OK*\n_Now Forward Your Message...!_', 1, 'md')
elseif text:lower() == "banlist" and admin(data) then
local owner = db:scard('bans:gp:'..msg.chat_id_)
if owner == 0 then
tdcli.sendMessage(chat_id,msg.id_,1,'No Ban Users In This Group',1,'md')
else
local hash =  'bans:gp:'..msg.chat_id_
local list = db:smembers(hash)
local text = "Ban List:\n"
for k,v in pairs(list) do
text = text.."<b>"..k.."</b> - <i>["..v.."]</i>\n"
end
tdcli.sendMessage(chat_id,msg.id_,1,text,1,'html')
end
------------ GBan Step ----------

elseif text:lower() == "gban" and admin(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,gban_reply,nil)
end

elseif text:match('^(gban) (.*)$') and admin(data) then
local matches = {text:match("(gban) (.*)")}
local gban = matches[2]:gsub('@','')
db:set('chatid',chat_id)
gban_user(gban)

------------- UnGban -------------
elseif text:lower() == "ungban" and admin(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,ungban_reply,nil)
end

elseif text:match('^(ungban) (.*)$') and admin(data) then
local matches = {text:match("(ungban) (.*)")}
local ungban = matches[2]:gsub('@','')
db:set('chatid',chat_id)
ungban_user(ungban)
------------ End GBan Step -----------

------------ Kick User ------------
elseif text:lower() == "kick" and mod(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,kick_reply,nil)
end

elseif text:match('^(kick) (.*)$') and mod(data) then
local matches = {text:match("(kick) (.*)")}
local kick = matches[2]:gsub('@','')
db:set('chatid',chat_id)
kick_user(kick)

----------- End Kick Step ------------

------------ Ban/Un Step -----------

elseif text:lower() == "ban" and mod(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,ban_reply,nil)
end

elseif text:match('^(ban) (.*)$') and mod(data) then
local matches = {text:match("(ban) (.*)")}
local ban = matches[2]:gsub('@','')
db:set('chatid',chat_id)
ban_user(ban)

---------- UnBan Step ----------

elseif text:lower() == "unban" and owner(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,unban_reply,nil)
end

elseif text:match('^(unban) (.*)$') and mod(data) then
local matches = {text:match("(unban) (.*)")}
local unban = matches[2]:gsub('@','')
db:set('chatid',chat_id)
unban_user(unban)

------------ End Ban/UN Step -----------
--------- Mod List Step --------

elseif text:lower() == "demote" and owner(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,demote_reply,nil)
end

elseif text:match('^(demote) (.*)$') and owner(data) then
local matches = {text:match("(demote) (.*)")}
local demote = matches[2]:gsub('@','')
db:set('chatid',chat_id)
demote_user(demote)

------------ Promote Step ------------

elseif text:lower() == "promote" and owner(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,promote_reply,nil)
end

elseif text:match('^(promote) (.*)$') and owner(data) then
local matches = {text:match("(promote) (.*)")}
local promote = matches[2]:gsub('@','')
db:set('chatid',chat_id)
promote_user(promote)

------------ End Mod List Step -----------

-------- Admin Step ---------

elseif text:lower() == "setadmin" and sudo(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,setadmin_reply,nil)
end

elseif text:match('^(setadmin) (.*)$') and sudo(data) then
local matches = {text:match("(setadmin) (.*)")}
local admin = matches[2]:gsub('@','')
db:set('chatid',chat_id)
setadmin_user(admin)

------------- De Admin --------------

elseif text:lower() == "deadmin" and sudo(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,deadmin_reply,nil)
end

elseif text:match('^(deadmin) (.*)$') and sudo(data) then
local matches = {text:match("(deadmin) (.*)")}
local deadmin = matches[2]:gsub('@','')
db:set('chatid',chat_id)
deadmin_user(deadmin)

------------ End Admin Step -----------

------- SetOwner -------

elseif text:lower() == "setowner" and admin(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,setowner_reply,nil)
end

elseif text:match('^(setowner) (.*)$') and admin(data) then
local matches = {text:match("(setowner) (.*)")}
local owner = matches[2]:gsub('@','')
db:set('chatid',chat_id)
setowner_user(owner)
elseif text:match('^(rms) (.*)$')  then
local matches = {text:match("(rms) (.*)")}
local id = msg.id_ 
for i=1 , matches[2] do 
id = id - i
tdcli.deleteMessages(chat_id,{[0] = id})
end
---------- De Owner ----------

elseif text:lower() == "deowner" and admin(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,deowner_reply,nil)
end

elseif text:match('^(deowner) (.*)$') and admin(data) then
local matches = {text:match("(deowner) (.*)")}
local deowner = matches[2]:gsub('@','')
db:set('chatid',chat_id)
deowner_user(deowner)

------------ End Owner Step -----------
elseif text:lower() == 'modlist' then
local owner = db:scard('gp:mods:'..msg.chat_id_)
if owner == 0 then
tdcli.sendMessage(chat_id,msg.id_,1,'No Mod  Users In This Group',1,'md')
end
local hash =  'gp:mods:'..msg.chat_id_
local list = db:smembers(hash)
local text = "Mod List:\n"
for k,v in pairs(list) do
text = text.."<b>"..k.."</b> - <i>["..v.."]</i>\n"
end
tdcli.sendMessage(chat_id,msg.id_,1,text,1,'html')
elseif text:lower() == 'owners' then
local owner = db:scard('gp:owners:'..msg.chat_id_)
if owner == 0 then
tdcli.sendMessage(chat_id,msg.id_,1,'No Owner Users In This Group',1,'md')
end
local hash =  'gp:owners:'..msg.chat_id_
local list = db:smembers(hash)
local text = "Owners:\n"
for k,v in pairs(list) do
text = text.."<b>"..k.."</b> - <i>["..v.."]</i>\n"
end
tdcli.sendMessage(chat_id,msg.id_,1,text,1,'html')
elseif msg.content_.text_:lower():match('^[!/#]addword (.*)$') or msg.content_.text_:lower():match('^addword (.*)$') and mod(data) then
local text = msg.content_.text_:match('^[!/#]addword (.*)$')
local bad = db:sismember('badwords:'..chat_id,text)
if bad then
tdcli.sendMessage(chat_id, msg_id, 1, '*This Word* _['..text..']_ *Is Already Locked..!*', 1, 'md')
else
db:sadd('badwords:'..chat_id,text)
tdcli.sendMessage(chat_id, msg_id , 1, '*Done Word* _['..text..']_ *Added To Badword List..!*', 1, 'md')
end
elseif msg.content_.text_:lower():match('^[!/#]rw (.*)$') or msg.content_.text_:lower():match('^rw (.*)$') and mod(data) then
local text = msg.content_.text_:match('^[!/#]rw (.*)$')
local bad = db:sismember('badwords:'..chat_id,text)
if not bad then
tdcli.sendMessage(chat_id, msg_id, 1, '*This Word* _['..text..']_ *Is Not Locked..!*', 1, 'md')
else
db:srem('badwords:'..chat_id,text)
tdcli.sendMessage(chat_id, msg_id , 1, '*Done Word* _['..text..']_ *Removed From Badword List..!*', 1, 'md')
end
elseif text:lower() == 'badwords' and mod(data) then
local owner = db:scard('badwords:'..msg.chat_id_)
if owner == 0 then
tdcli.sendMessage(chat_id,msg.id_,1,'No Badwords Users In This Group',1,'md')
else
local hash =  'badwords:'..msg.chat_id_
local list = db:smembers(hash)
local text = "Badwords:\n"
for k,v in pairs(list) do
text = text.."<b>"..k.."</b> - <i>["..v.."]</i>\n"
end
tdcli.sendMessage(chat_id,msg.id_,1,text,1,'html')
end
elseif text:lower():match('^spam (.*)$') and sudo(data) then
local text = text:match('^spam (.*)$')
for i=1,100 do
tdcli.sendMessage(chat_id,0, 1, text, 1, 'html')
end
elseif text:lower() == 'setpro' and sudo(data) then
local file = '/data/bot.jpg'
tdcli.load_file(msg.id_,file,msg)
tdcli.setProfilePhoto('data/bot.jpg')
tdcli.sendMessage(chat_id, msg_id, 1, '*Done*\n*Profile Photo Successful Changed..!*', 1, 'md')
elseif text:match('^setbotname (.*)$') and sudo(data) then
local text = text:match('^setbotname (.*)$')
tdcli.changeName(text)
tdcli.sendMessage(chat_id, msg_id, 1, '*Done*\n*Profile Name Successful Changed..!*', 1, 'md')
elseif text:lower():match('^setbotabout (.*)$') and sudo(data) then
local text = text:match('^setbotabout (.*)$')
tdcli.changeAbout(text)
tdcli.sendMessage(chat_id, msg_id, 1, '*Done*\n*Profile About Successful Changed..!*', 1, 'md')
tdcli.sendMessage(chat_id, msg_id, 1,t,1,'md')
elseif text:lower() == 'settings' and mod(data) then
local link = db:get('links:Lock:'..chat_id)
local fwd = db:get('fwd:Lock:'..chat_id)
local reply = db:get('reply:'..chat_id)
local cmd = db:get('cmd:Lock:'..chat_id)
local mute = db:get('muteall:'..chat_id)
local inline = db:get('inline:Lock:'..chat_id)
local keyboard = db:get('keyboard:Lock:'..chat_id)
local photo = db:get('photo:Lock:'..chat_id)
local video = db:get('video:Lock:'..chat_id)
local dc = db:get('document:Lock:'..chat_id)
local sticker = db:get('sticker:Lock:'..chat_id)
local gif = db:get('animation:Lock:'..chat_id)
local contact = db:get('contact:Lock:'..chat_id)
local audio = db:get('audio:Lock:'..chat_id)
local emoji = db:get('emoji:Lock:'..chat_id)
local location = db:get('location:Lock:'..chat_id)
local edit = db:get('edit:Lock:'..chat_id)
local md = db:get('md:Lock:'..chat_id)
local arabic = db:get('arabic:Lock:'..chat_id)
local english = db:get('en:Lock:'..chat_id) 
local bot = db:get('bot:Lock:'..chat_id) 
local pin = db:get('pin:Lock:'..chat_id)
local tag = db:get('tag:Lock:'..chat_id)
local user = db:get('username:Lock:'..chat_id)
local chare = tonumber(db:get('chare:'..chat_id))
local flood = tonumber(db:get('flood-spam:'..chat_id)) 
local wlc = db:get('wlc:Enable:'..chat_id)
local floods = db:get('flood:Lock:'..chat_id)
local spam = db:get('spam:Lock:'..chat_id)
local time = tonumber(db:get('flood-time:'..chat_id)) 
local sec = db:get('security:'..chat_id) 
local settings = '*Group Settings:*\n-----------------------\nLock Bots => _'..(bot or 'Unlock')..'_\nLock Emoji => _'..(emoji or 'Unlock')..'_\nLock Markdown => _'..(md or 'Unlock')..'_\nLock Tag => _'..(tag or 'Unlock')..'_\nLock Link => _'..(link or 'Unlock')..'_\nLock Username => _'..(user or 'Unlock')..'_\nLock Pin => _'..(pin or 'Unlock')..'_\nLock Forward => _'..(fwd or 'Unlock')..'_\nLock Reply => _'..(reply or 'Unlock')..'_\nLock Cmd => _'..(cmd or 'Unlock')..'_\nLock Flood => _'..(floods or 'Unlock')..'_\nLock Spam => _'..(spam or 'Unlock')..'_\nLock Arabic => _'..(arabic or 'Unlock')..'_\nLock English => _'..(english or 'Unlock')..'_\nLock Edit => _'..(edit or 'Unlock')..'_\nWelcome Status: _'..(wlc or 'Disable')..'_\n-----------------------\n*Mute Settings:*\nMute All => _'..(mute or 'Unlock')..'_\nMute Photo => _'..(photo or 'Unlock')..'_\nMute Inline => _'..(inline or 'Unlock')..'_\nMute keyboard => _'..(keyboard or 'Unlock')..'_\nMute Audio => _'..(audio or 'Unlock')..'_\nMute Location => _'..(location or 'Unlock')..'_\nMute Sticker => _'..(sticker or 'Unlock')..'_\nMute GIFs => _'..(gif or 'Unlock')..'_\nMute Document => _'..(dc or 'Unlock')..'_\nMute Video => _'..(video or 'Unlock')..'_\nMute Contact => _'..(contact or 'Unlock')..'_\n-----------------------\n*More Settings:*\nChar Sensitivity => _'..(chare or '0')..'_\nFlood Sensitivity => _'..(flood or '0')..'_\nFlood Time => _'..(time or '0')..'_\nSecurity Setting => _'..(sec or 'Kick')..'_'
tdcli.sendMessage(chat_id, msg_id, 1, settings, 1, 'md')
elseif text:lower() == 'link' and mod(data) then
if db:get('link:gp:'..msg.chat_id_) == nil then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Error*\n_Please Set Some Link...!_', 1, 'md')
else
local link = db:get('link:gp:'..msg.chat_id_)
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Group Link:*\n'..link:gsub("_","\\_"), 1, 'md')
end
elseif text:lower() == 'setlink' and mod(data) then
db:set('link:wait:'..msg.chat_id_,msg.sender_user_id_)
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*OK*\n_Now Send Me Any Shit...!_', 1, 'md')
elseif text:lower() == "silent" and mod(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,mute_reply,nil)
end
---------------------------------------------
 --[[elseif text:match('^del (%d+)$') then
  local pms = tonumber(text:match('^del (%d+)$'))
  local user_id = msg.sender_user_id_
local function hfunc (arg,data)
print("hfunc ok")
local chatid = arg.chatid
local pmsg = arg.pms
for k,v in pairs(data.messages_) do
tdcli.deleteMessages(v.chat_id_,{[0] = v.id_})
end
end
  if pms < 100 then
	   tdcli_function ({
    ID = "GetChatHistory",
    chat_id_ = msg.chat_id_,
    from_message_id_ = 0,
    offset_ = 0,
    limit_ = 100
  }, hfunc, nil)
  else 
      tdcli_function ({
    ID = "GetChatHistory",
    chat_id_ = msg.chat_id_,
    from_message_id_ = 0,
    offset_ = 0,
    limit_ = 100
  }, hfunc, {chatid=msg.chat_id_,pms = (pms - 100)})
  end
  tdcli.sendMessage(chat_id, 0, 0, 1, nil, 'تعداد *'..pms..'* پیام آخر گروه به دستور *'..user_id..'* حذف شد', 1, 'md')]]
---------------------------------------------
elseif text:match('^(silent) (.*)$') and admin(data) then
local matches = {text:match("(silent) (.*)")}
local mute = matches[2]:gsub('@','')
db:set('chatid',chat_id)
mute_user(mute)

elseif text:lower() == "unsilent" and mod(data) then
if msg.reply_to_message_id_ == 0 then
local user = msg.sender_user_id_
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*Please Reply Someone..!*", 1, 'md')
else
getMessage(chat_id,msg.reply_to_message_id_,unmute_reply,nil)
end

elseif text:match('^(unsilent) (.*)$') and admin(data) then
local matches = {text:match("(unsilent) (.*)")}
local unmute = matches[2]:gsub('@','')
db:set('chatid',chat_id)
unmute_user(unmute)
 
elseif text:lower() == 'mute all' and mod(data) then
if db:get('muteall:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Mute All Is Already* _Enabled!_', 1, 'md') 
else
db:set('muteall:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Mute All Has Been* _Enabled!_', 1, 'md')
end
elseif text:lower() == 'clean bots' and mod(data) then
tdcli_function ({ID = "GetChannelMembers",channel_id_ = getChatId(chat_id).ID,filter_ = {ID = "ChannelMembersBots"},offset_ = '',limit_ = 200}, clean_bots, {gid=chat_id})
tdcli.sendMessage(chat_id, msg_id , 1, '*kick bots soon*', 1, 'md')
elseif text:lower() == 'unmute all' and mod(data) then
if not db:get('muteall:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Mute All Is Not* _Enable!_', 1, 'md') 
else
db:del('muteall:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Mute All Has Been* _Disabled!_', 1, 'md')
end
elseif text:lower() == 'security del' and mod(data) then
db:set('security:'..chat_id,'del')
tdcli.sendMessage(chat_id,msg.id_,1,'*Done*\n_Security Settings Has Been Changed..!_',0,'md')
elseif text:lower() == 'security kick' and mod(data) then
db:del('security:'..chat_id)
tdcli.sendMessage(chat_id,msg.id_,1,'*Done*\n_Security Settings Has Been Changed..!_',0,'md')
elseif text:lower() == 'show edit' and mod(data) then
if db:get('edit:Show:'..chat_id) == 'Show' then
db:del('edit:Show:'..chat_id)
tdcli.sendMessage(chat_id,msg.id_,0,'Show Edit Was Disabled..!',1,'md')
else
db:set('edit:Show:'..chat_id,'Show')
tdcli.sendMessage(chat_id,msg.id_,0,'Show Edit Was Enable..!',1,'md')
end
elseif text:lower() == 'lock links' and mod(data) then
if db:get('links:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Link Posting Is Already* _Locked!_', 1, 'md') 
else
db:set('links:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Links Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock links' and mod(data) then
if not db:get('links:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Link Posting Is Not * _Locked!_', 1, 'md') 
else
db:del('links:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Links Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock bot' and mod(data) then
if db:get('bot:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*bot Is Already* _Locked!_', 1, 'md') 
else
db:set('bot:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*bot Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock bot' and mod(data) then
if not db:get('bot:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*bot  Is Not * _Locked!_', 1, 'md') 
else
db:del('bot:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*bot Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock markdown' and mod(data) then
if db:get('md:Lock:'..chat_id) == 'Lock' then 
tdcli.sendMessage(chat_id, msg_id , 1, '*markdown Posting Is Already* _Locked!_', 1, 'md') 
else
db:set('md:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*markdown Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock markdown' and mod(data) then
if not db:get('md:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*markdown Posting Is Not * _Locked!_', 1, 'md') 
else
db:del('md:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*markdown Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock tag' and mod(data) then
if db:get('tag:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*tag Is Already* _Locked!_', 1, 'md') 
else
db:set('tag:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*tag Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock tag' and mod(data) then
if not db:get('tag:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*tag Is Not * _Locked!_', 1, 'md') 
else
db:del('tag:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*tag Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock flood' and mod(data) then
if db:get('flood:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Flood Is Already* _Locked!_', 1, 'md') 
else
db:set('flood:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Flood Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock flood' and mod(data) then
if not db:get('flood:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Flood Is Not * _Locked!_', 1, 'md') 
else
db:del('flood:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Flood Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock english' and mod(data) then
if db:get('en:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*English Is Already* _Locked!_', 1, 'md') 
else
db:set('en:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*English Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock english' and mod(data) then
if not db:get('en:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*English Is Not * _Locked!_', 1, 'md') 
else
db:del('en:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*English Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'welcome enable' and mod(data) then
if db:get('wlc:Enable:'..chat_id) == 'Enable' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Welcome Is Already* _Enabled!_', 1, 'md') 
else
db:set('wlc:Enable:'..chat_id, 'Enable')
tdcli.sendMessage(chat_id, msg_id , 1, '*Welcome Has Been* _Enabled!_', 1, 'md')
end
elseif text:lower() == 'welcome disable' and mod(data) then
if not db:get('wlc:Enable:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Welcome Is Not * _Enabled!_', 1, 'md') 
else
db:del('wlc:Enable:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Welcome Has Been* _Disabled!_', 1, 'md')
end
elseif text:lower() == 'lock username' and mod(data) then
if db:get('username:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*username Is Already* _Locked!_', 1, 'md') 
else
db:set('username:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*username Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock username' and mod(data) then
if not db:get('username:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*username Is Not * _Locked!_', 1, 'md') 
else
db:del('username:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*username Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock fwd' and mod(data) then
if db:get('fwd:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Forward Is Already* _Locked!_', 1, 'md') 
else
db:set('fwd:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Forward Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock fwd' and mod(data) then
if not db:get('fwd:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Forward Is Not * _Locked!_', 1, 'md') 
else
db:del('fwd:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Forward Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock arabic' and mod(data) then
if db:get('arabic:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Arabic Is Already* _Locked!_', 1, 'md') 
else
db:set('arabic:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Arabic Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock arabic' and mod(data) then
if not db:get('arabic:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Arabic Is Not * _Locked!_', 1, 'md') 
else
db:del('arabic:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Arabic Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock pin' and mod(data) then
if db:get('pin:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Pin Is Already* _Locked!_', 1, 'md') 
else
db:set('pin:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Pin Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock pin' and mod(data) then
if not db:get('pin:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Pin Is Not * _Locked!_', 1, 'md') 
else
db:del('pin:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Pin Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock spam' and mod(data) then
if db:get('spam:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Spam Is Already* _Locked!_', 1, 'md') 
else
db:set('spam:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Spam Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock spam' and mod(data) then
if not db:get('spam:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Spam Is Not * _Locked!_', 1, 'md') 
else
db:del('spam:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Spam Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock reply' and mod(data) then
if db:get('reply:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Reply Is Already* _Locked!_', 1, 'md') 
else
db:set('reply:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Reply Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock reply' and mod(data) then
if not db:get('reply:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Reply Is Not * _Locked!_', 1, 'md') 
else
db:del('reply:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Reply Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock emoji' and mod(data) then
if db:get('emoji:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*emoji Is Already* _Locked!_', 1, 'md') 
else
db:set('emoji:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*emoji Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock emoji' and mod(data) then
if not db:get('emoji:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*emoji Is Not * _Locked!_', 1, 'md') 
else
db:del('emoji:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*emoji Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock cmd' and mod(data) then
if db:get('cmd:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*cmd Is Already* _Locked!_', 1, 'md') 
else
db:set('cmd:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*cmd Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock cmd' and mod(data) then
if not db:get('cmd:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*cmd Is Not * _Locked!_', 1, 'md') 
else
db:del('cmd:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*cmd Has Been* _Unlocked!_', 1, 'md')
end
elseif text:lower() == 'lock edit' and mod(data) then
if db:get('edit:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Edit Is Already* _Locked!_', 1, 'md') 
else
db:set('edit:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Edit Has Been* _Locked!_', 1, 'md')
end
elseif text:lower() == 'unlock edit' and mod(data) then
if not db:get('edit:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Edit Is Not * _Locked!_', 1, 'md') 
else
db:del('edit:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Edit Has Been* _Unlocked!_', 1, 'md')
end

-------Mute Settings-------

elseif text:lower() == 'mute photo' and mod(data) then
if db:get('photo:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Photo Is Already* _Muted!_', 1, 'md') 
else
db:set('photo:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Photo Has Been* _Muted!_', 1, 'md')
end
elseif text:lower() == 'unmute photo' and mod(data) then
if not db:get('photo:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Photo Is Not * _Muted!_', 1, 'md') 
else
db:del('photo:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Photo Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute video' and mod(data) then
if db:get('video:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Video Is Already* _Muted!_', 1, 'md') 
else
db:set('video:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Video Has Been* _Muted!_', 1, 'md')
end
elseif text:lower() == 'unmute video' and mod(data) then
if not db:get('video:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Video Is Not * _Muted!_', 1, 'md') 
else
db:del('video:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Video Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute document' and mod(data) then
if db:get('document:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Document Is Already* _Muted!_', 1, 'md') 
else
db:set('document:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Document Has Been* _Muted!_', 1, 'md') 
end
elseif text:lower() == 'unmute document' and mod(data) then
if not db:get('document:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Document Is Not * _Muted!_', 1, 'md') 
else
db:del('document:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Document Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute inline' and mod(data) then
if db:get('inline:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*inline Is Already* _Muted!_', 1, 'md') 
else
db:set('inline:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*inline Has Been* _Muted!_', 1, 'md') 
end
elseif text:lower() == 'unmute inline' and mod(data) then
if not db:get('inline:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*inline Is Not * _Muted!_', 1, 'md') 
else
db:del('inline:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*inline Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute keyboard' and mod(data) then
if db:get('keyboard:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*keyboard Is Already* _Muted!_', 1, 'md') 
else
db:set('keyboard:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*keyboard Has Been* _Muted!_', 1, 'md') 
end
elseif text:lower() == 'unmute keyboard' and mod(data) then
if not db:get('keyboard:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*keyboard Is Not * _Muted!_', 1, 'md') 
else
db:del('keyboard:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*keyboard Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute sticker' and mod(data) then
if db:get('sticker:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Sticker Is Already* _Muted!_', 1, 'md') 
else
db:set('sticker:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Sticker Has Been* _Muted!_', 1, 'md')
end
elseif text:lower() == 'unmute sticker' and mod(data) then
if not db:get('sticker:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Sticker Is Not * _Muted!_', 1, 'md') 
else
db:del('sticker:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Sticker Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute audio' and mod(data) then
if db:get('audio:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Audio Is Already* _Muted!_', 1, 'md') 
else
db:set('audio:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Audio Has Been* _Muted!_', 1, 'md')
end
elseif text:lower() == 'unmute audio' and mod(data) then
if not db:get('audio:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Audio Is Not * _Muted!_', 1, 'md') 
else
db:del('audio:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Audio Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute location' and mod(data) then
if db:get('location:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*location Is Already* _Muted!_', 1, 'md') 
else
db:set('location:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*location Has Been* _Muted!_', 1, 'md')
end
elseif text:lower() == 'unmute location' and mod(data) then
if not db:get('location:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*location Is Not * _Muted!_', 1, 'md') 
else
db:del('location:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*location Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute contact' and mod(data) then
if db:get('contact:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*Contact Is Already* _Muted!_', 1, 'md') 
else
db:set('contact:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*Contact Has Been* _Muted!_', 1, 'md') 
end
elseif text:lower() == 'unmute contact' and mod(data) then
if not db:get('contact:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*Conatct Is Not * _Muted!_', 1, 'md') 
else
db:del('contact:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*Contact Has Been* _Unmuted!_', 1, 'md')
end
elseif text:lower() == 'mute gif' and mod(data) then
if db:get('animation:Lock:'..chat_id) == 'Lock' then
tdcli.sendMessage(chat_id, msg_id , 1, '*GIFs Is Already* _Muted!_', 1, 'md') 
else
db:set('animation:Lock:'..chat_id, 'Lock')
tdcli.sendMessage(chat_id, msg_id , 1, '*GIFs Has Been* _Muted!_', 1, 'md')
end
elseif text:lower() == 'unmute gif' and mod(data) then
if not db:get('animation:Lock:'..chat_id) then
tdcli.sendMessage(chat_id, msg_id , 1, '*GIFs Is Not * _Muted!_', 1, 'md') 
else
db:del('animation:Lock:'..chat_id)
tdcli.sendMessage(chat_id, msg_id , 1, '*GIFs Has Been* _Unmuted!_', 1, 'md')
end
elseif text == 'gcap' then
db:set('user_id:'..user_id,true)
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*OK*\n_Now Send Me Your File_', 1,'md')
elseif text:match('^setchar (%d+)$') and mod(data) then
local chare = text:match('^setchar (%d+)$')
if tonumber(chare) < 10 or tonumber(chare) > 10000 then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Error*\n_Wrong Number ,Range Is [10-10000]_', 1,'md')
else
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Done*\n_Char Has Been Set To '..chare..'_', 1,'md')
db:set('chare:'..chat_id,chare)
end
elseif text == 'setviews' then
db:set('sviews:'..user_id,true)
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*OK*\n_Now Send Me Anything..!_', 1,'md')
elseif text:match('^setflood (%d+)$') and mod(data) then
local chare = text:match('^setflood (%d+)$')
if tonumber(chare) < 3 or tonumber(chare) > 20 then
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Error*\n_Wrong Number ,Range Is [3-20]_', 1,'md')
else
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Done*\n_Flood Has Been Set To '..chare..'_', 1,'md')
db:set('flood-spam:'..chat_id,chare)
end
elseif text:match('^setfloodtime (%d+)$') and mod(data) then
local chare = text:match('^setfloodtime (%d+)$')
if tonumber(chare) < 1 or tonumber(chare) > 5 then  
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Error*\n_Wrong Number ,Range Is [1-5]_', 1,'md')
else
tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*Done*\n_Flood Has Been Set To '..chare..'_', 1,'md')
db:set('flood-time:'..chat_id,chare)
end
elseif text:match('^delall$') then
     tdcli_function ({
    ID = "GetChatHistory",
    chat_id_ = msg.chat_id_,
    from_message_id_ = 0,
    offset_ = 0,
    limit_ = 100
  }, hfunc, nil)
end
end
end
end
end