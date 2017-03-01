//
//  ViewController.m
//  CocoaSyncSocket
//
//  Created by zfy on 16/12/26.
//  Copyright © 2016年 zfy. All rights reserved.
//

#import "ViewController.h"

#import "GCDAsyncSocket.h" // for TCP
#import "MBProgressHUD_Tips.h"

@interface ViewController ()<GCDAsyncSocketDelegate>

{
    GCDAsyncSocket *gcdSocket;
    GCDAsyncSocket *_severSocket;
}
@property (weak, nonatomic) IBOutlet UITextField *sendFiled;

@property (weak, nonatomic) IBOutlet UIButton *sendBtn;

@property (weak, nonatomic) IBOutlet UILabel *recieveLal;

@property (weak, nonatomic) IBOutlet UIButton *connectBtn;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIButton *disConnectBtn;

@property (nonatomic,strong)NSThread *thread;

@property (weak, nonatomic) IBOutlet UITextField *sendContentText;

/**
 *  两个手机  同时为服务器  同时也是客户端  注意两边 ip 都要填写
 *
 */
@end

static  NSString * Khost = @"192.168.199.139";  //192.168.199.183 我自己当时写的默认特征值
static const uint16_t Kport = 5566;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
  
    
    [_connectBtn addTarget:self action:@selector(connectAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_disConnectBtn addTarget:self action:@selector(disConnectAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_sendBtn addTarget:self action:@selector(sendAction) forControlEvents:UIControlEventTouchUpInside];
    //  用户端
    gcdSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    //服务端
    _severSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSLog(@"%@ --- %@", gcdSocket , _severSocket);//证明 不是单例
    if ([_severSocket acceptOnPort:Kport error:nil]) {
        //NSLog(@"服务端监听到了 服务");
    }
    [gcdSocket acceptOnPort:Kport error:nil];
    _sendFiled.placeholder = @"填入IP";
    _sendFiled.text = Khost;
    _socketArray=[[NSMutableArray alloc]init];//保存 套接字
    
}


//连接
- (void)connectAction
{
    [self connect];

}
//断开连接
- (void)disConnectAction
{
     [gcdSocket disconnect];
}

//发送消息
- (void)sendAction
{
    if (_sendContentText.text.length == 0) {
        return;
    }
    NSData * data = [self.sendContentText.text dataUsingEncoding:NSUTF8StringEncoding];
    
    _textView.text=[NSString stringWithFormat:@"%@我说 ：%@\n",_textView.text,self.sendContentText.text];
    self.sendContentText.text =@"";
    
    [ self sendData:data :@"txt" ];

}

#pragma mark - 对外的一些接口

//建立连接
- (BOOL)connect
{
    if (_sendFiled.text.length == 0) {
       
    }else{
        
    }
    
   return  [gcdSocket connectToHost:_sendFiled.text onPort:Kport error:nil];
    //    return [gcdSocket connectToUrl:[NSURL fileURLWithPath:@"/Users/tuyaohui/IPCTest"] withTimeout:-1 error:nil];
}

//断开连接
- (void)disConnect
{
    [gcdSocket disconnect];
}

//字典转为Json字符串
- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}




- (void)sendMsg:(NSString *)msg
{
    
    //    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"test1" ofType:@"jpg"];
    //
    //    NSData *data5 = [NSData dataWithContentsOfFile:filePath];
    //
    //    [self sendData:data5 :@"img"];
}

//服务端接收到连接成功
- (void)socket:(GCDAsyncSocket *)sender didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [_socketArray addObject:newSocket];
    //监听客户端有没有发送消息
    [newSocket readDataWithTimeout:-1 tag:0];//读取客户端发来的消息
    NSLog(@"服务端 接收到链接");
    [MBProgressHUD showError:@"服务断接收到连接"];
    // The "sender" parameter is the listenSocket we created.
    // The "newSocket" is a new instance of GCDAsyncSocket.
    // It represents the accepted incoming client connection.
    
    // Do server stuff with newSocket...
}

// 服务端接收到数据的回调 或客户端
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"收到消息：%@",msg);
    
    NSString*str=[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    //IP:text
    _textView.text=[NSString stringWithFormat:@"%@%@:%@\n",_textView.text,sock.connectedHost,str];
    //继续监听
    [sock readDataWithTimeout:-1 tag:0];
    //[self pullTheMsg];
}

- (void)sendData:(NSData *)data :(NSString *)type
{
    NSUInteger size = data.length;
    
    NSMutableDictionary *headDic = [NSMutableDictionary dictionary];
    [headDic setObject:type forKey:@"type"];
    [headDic setObject:[NSString stringWithFormat:@"%ld",(unsigned long)size] forKey:@"size"];
    NSString *jsonStr = [self dictionaryToJson:headDic];
    
    
    NSData *lengthData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSMutableData *mData = [NSMutableData dataWithData:lengthData];
    //分界
    [mData appendData:[GCDAsyncSocket CRLFData]];
    
    [mData appendData:data];
    
    
    //第二个参数，请求超时时间
    [gcdSocket writeData:mData withTimeout:-1 tag:110];
    
}

//监听最新的消息
- (void)pullTheMsg
{
    //貌似是分段读数据的方法
    //    [gcdSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:10 maxLength:50000 tag:110];
    
    //监听读数据的代理，只能监听10秒，10秒过后调用代理方法  -1永远监听，不超时，但是只收一次消息，
    //所以每次接受到消息还得调用一次
    [gcdSocket readDataWithTimeout:-1 tag:110];
    
}

//用Pingpong机制来看是否有反馈
- (void)checkPingPong
{
    //pingpong设置为3秒，如果3秒内没得到反馈就会自动断开连接
    [gcdSocket readDataWithTimeout:3 tag:110];
    
}



#pragma mark - GCDAsyncSocketDelegate
//连接成功调用
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"连接成功,host:%@,port:%d",host,port);
    [MBProgressHUD showError:@"连接到host"];
    [self pullTheMsg];
    
    //[sock startTLS:nil];
    
    //心跳写在这...
}

//断开连接的时候调用
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    NSLog(@"断开连接,host:%@,port:%d",sock.localHost,sock.localPort);
    [MBProgressHUD showError:@"与服务端断开连接"];
    //断线重连写在这...
    
}

//写的回调
- (void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"写的回调,tag:%ld",tag);
    //判断是否成功发送，如果没收到响应，则说明连接断了，则想办法重连
    [self pullTheMsg];
}



//Unix domain socket
//- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url
//{
//    NSLog(@"connect:%@",[url absoluteString]);
//}

//    //看能不能读到这条消息发送成功的回调消息，如果2秒内没收到，则断开连接
//    [gcdSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:2 maxLength:50000 tag:110];

//貌似触发点
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    
    NSLog(@"读的回调,length:%ld,tag:%ld",partialLength,tag);
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [_sendFiled resignFirstResponder];
    [_sendContentText resignFirstResponder];
    
}
//为上一次设置的读取数据代理续时 (如果设置超时为-1，则永远不会调用到)
//-(NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
//{
//    NSLog(@"来延时，tag:%ld,elapsed:%f,length:%ld",tag,elapsed,length);
//    return 10;
//}



@end
