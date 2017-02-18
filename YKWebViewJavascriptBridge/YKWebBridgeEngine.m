//
//  YKWebBridgeEngine.m
//  YKWebViewJavascriptBridgeDemo
//
//  Created by York on 2017/2/17.
//  Copyright © 2017年 YK-Unit. All rights reserved.
//

#import "YKWebBridgeEngine.h"

NSString * YKWebBridgeEngine_js() {
    
    /*
     #define Conn(x,y) x##y  //两个##表示连接，如int n=Conn(12,34)，n为1234
     #define ToChar(x) #@x   //#@表示加上单引号，如 char a=ToChar(1)，a为'1'
     #define ToString(x) #x  //#表示加上双引号，如 string str=toString(123)，str为"123"
     */
#define __wvjb_js_func__(x) #x
    
    // BEGIN preprocessorJSCode
    static NSString * preprocessorJSCode = @__wvjb_js_func__(
                                                             ;(function() {
        if (window.YKWebBridgeEngine) {
            return;
        }
        
        window.YKWebBridgeEngine = {
        addMessageHandler: addMessageHandler,
        removeMessageHandler: removeMessageHandler,
        sendMessage: sendMessage,
        _bridgeEngineDidWriteData: _bridgeEngineDidWriteData,
        _bridgeEngineDidReadData: _bridgeEngineDidReadData
        };
        
        var messageHandlerDict = {};
        var responseCallbackDict = {};
        var uniqueId = 0;
        
        function addMessageHandler(name, handler) {
            if (name && handler) {
                messageHandlerDict[name] = handler;
            }
        }
        
        function removeMessageHandler(name) {
            if (name) {
                delete messageHandlerDict[name];
            }
        }
        
        function sendMessage(messageName, data, responseCallback) {
            if (arguments.length == 2 && typeof data == 'function') {
                responseCallback = data;
                data = null;
            }
            
            var reqId = ++uniqueId;
            
            var messgaeDict = {};
            messgaeDict['reqId'] = reqId;
            messgaeDict['name'] = messageName;
            messgaeDict['data'] = data;
            
            if (responseCallback) {
                responseCallbackDict[reqId] = responseCallback;
            }
            
            var jsonMessage = JSON.stringify(messgaeDict);
            _bridgeEngineDidWriteData(jsonMessage);
        }
        
        function _bridgeEngineDidWriteData(jsonMessage) {
            window.webkit.messageHandlers.NativeBridgeEngineDidReadData.postMessage(jsonMessage);
        }
        
        function _bridgeEngineDidReadData(jsonMessage) {
            var messageDict = JSON.parse(jsonMessage);

            if (messageDict.hasOwnProperty('reqId')) {
                var reqId = messageDict['reqId'];
                var name = messageDict['name'];
                var data = messageDict['data'];
                
                if (!name) {
                    return;
                }
                
                var messageHandler = messageHandlerDict[name];
                if (!messageHandler) {
                    return;
                }
                
                var responseCallback = function(responseData) {
                    var respMessageDict = {};
                    respMessageDict['respId'] = reqId;
                    if (responseData) {
                        respMessageDict['data'] = responseData;
                    }
                    
                    var jsonMessage = JSON.stringify(respMessageDict);
                    _bridgeEngineDidWriteData(jsonMessage);
                };
                
                messageHandler(data,responseCallback);
                
            }else if(messageDict.hasOwnProperty('respId')) {
                var respId = messageDict['respId'];
                var respData = messageDict['data'];
                var responseCallback = responseCallbackDict[respId];
                if (responseCallback) {
                    responseCallback(respData);
                    delete responseCallbackDict[respId];
                }
            }
        }
        
    })();
                                                             );
    // END preprocessorJSCode
    
#undef __wvjb_js_func__
    return preprocessorJSCode;
};

