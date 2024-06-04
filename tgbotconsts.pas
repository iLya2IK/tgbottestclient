unit tgbotconsts;

{$mode ObjFPC}{$H+}

interface

const STATE_INIT     = 0;
      STATE_FINISHED = 1;
      STATE_TERMINATED = 2;

      TASK_NO_ERROR = 0;
      TASK_ERROR_ATTACH_REQ = $10;
      TASK_ERROR_CANT_EASY_CURL = $11;
      TASK_ERROR_GET_INFO = $12;
      TASK_ERROR_CURL = $13;

      METH_GET = 0;
      METH_POST = 1;
      METH_UPLOAD = 2;

const BAD_JSON = '{"ok":false}';
      OK_JSON  = '{"ok":true,"result":true}';
      JSON_EMPTY_OBJ = '{}';
      JSON_EMPTY_ARRAY = '[]';
      JSON_EMPTY_NESTED_ARRAY = '[[]]';
      JSON_TRUE = 'true';
      JSON_FALSE = 'false';

      BAD_JSON_DATABASE_FAIL     = '{"ok":false,"result":"DB Fail"}';
      BAD_JSON_JSON_PARSER_FAIL  = '{"ok":false,"result":"JSON Parser Fail"}';
      BAD_JSON_JSON_FAIL         = '{"ok":false,"result":"JSON Fail"}';
      BAD_JSON_INTERNAL_UNK      = '{"ok":false,"result":"Internal Exception"}';
      BAD_JSON_MALFORMED_REQUEST = '{"ok":false,"result":"Malformed Request"}';

      cOK        = 'ok';
      cRESULT    = 'result';
      cMSG       = 'msg';
      cMSGS      = 'msgs';
      cTEXT      = 'text';
      cDATA      = 'data';
      cURL       = 'url';
      cID        = 'id';
      cLANG      = 'language_code';
      cCBCKID    = 'callback_query_id';
      cCBCKDATA  = 'callback_data';
      cCID       = 'chat_id';
      cUID       = 'user_id';
      cMID       = 'message_id';
      CUPDID     = 'update_id';
      cNOTIFY    = 'notify';
      cCMDNOTIFY = 'commands_notify';
      cFROM      = 'from';
      cCHAT      = 'chat';
      cSNDCHAT   = 'sender_chat';
      cDATE      = 'date';
      cISBOT     = 'is_bot';
      cFIRSTNAME = 'first_name';
      cLASTNAME  = 'last_name';
      cUSERNAME  = 'username';
      cOFFSET    = 'offset';
      cLENGTH    = 'length';
      cTIMEOUT   = 'timeout';
      cLIMIT     = 'limit';
      cTYPE      = 'type';
      cPRIVATE   = 'private';
      cPARSEMODE = 'parse_mode';
      cREPLYPARAMS= 'reply_parameters';
      cREPLYMARKUP= 'reply_markup';
      cFORCEREPLY = 'force_reply';
      cINLINEKBRD = 'inline_keyboard';
      cENTITIES   = 'entities';
      cCOMMAND    = 'bot_command';
      cPAYLOAD    = 'payload';
      cMESSAGE    = 'message';
      cCALLBACK   = 'callback_query';
      cECOMMAND   = 'command';
      cDESCR      = 'description';

implementation

end.

