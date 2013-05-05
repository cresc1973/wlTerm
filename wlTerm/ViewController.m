/****************************************************************************
 *
 *  ViewController.m
 *  wlTerm
 *
 *  Created by tom on 2013/04/08.
 *  Copyright (c) 2013年 tom. All rights reserved.
 ***************************************************************************/
/*
 *
 *                  ・TxRxができるだけのターミナル完成
 *                  ・キーボードにテキストボックスとhideボタンとESCボタンを作成する
 *                  mIMCから参照する
 *                   -
 * 130414   v0.01   ・ターミナル用画面作成
 ***************************************************************************/

#import "ViewController.h"
#import "Konashi.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize bbtnFind, txtvTerm;

- (void) viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [Konashi initialize];
    
    // delegate設定
    txtvTerm.delegate = self;
    
    // keyboard shown hiden 
    [self registerForKeyboardNotifications];
    
    [Konashi addObserver:self selector:@selector(connected) name:KONASHI_EVENT_CONNECTED];
    [Konashi addObserver:self selector:@selector(ready) name:KONASHI_EVENT_READY];
    [Konashi addObserver:self selector:@selector(recvUartRx) name:KONASHI_EVENT_UART_RX_COMPLETE];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// for Konashi initialize
- (void) connected {
    NSLog(@"CONNECTED");
}
- (void) ready {
    
    NSLog(@"READY");
    
    [Konashi uartBaudrate:KONASHI_UART_RATE_9K6];
    [Konashi uartMode:KONASHI_UART_ENABLE];

    bbtnFind.tintColor = [UIColor greenColor];
    
    [Konashi pinMode:LED2 mode:OUTPUT];
    [Konashi digitalWrite:LED2 value:HIGH];
}
- (void) konashi_Find {
    bbtnFind.tintColor = [UIColor blackColor];
    [Konashi find];
}
- (IBAction)bbtnFind_Action:(id)sender {
    [self konashi_Find];
}

//
// recieve
//
- (void) recvUartRx {
    NSString *strRcvChr = [NSString stringWithFormat:@"%c", [Konashi uartRead]];
    NSString *strtxtvTerm = txtvTerm.text;
//    strRcv = [strRcv stringByAppendingString:strRcvChr];
    
    
    NSLog(@"UartRx %d", [Konashi uartRead]);
    if ([Konashi uartRead] != 13) {
        txtvTerm.text = [strtxtvTerm stringByAppendingString:strRcvChr];
        txtvTerm.selectedRange = NSMakeRange([txtvTerm.text length], 0);
    }
}


//
// transmit
//
- (void) trnsUartTx:(NSString *) strSendCmd {
//    NSData *data = [strSendCmd dataUsingEncoding:NSASCIIStringEncoding];
//    NSUInteger length = data.length;
//    
//    NSString *code = @"";
//    for (NSUInteger i=0;i<length;++i) {
//        unsigned char aBuffer[1];
//        [data getBytes:aBuffer range:NSMakeRange(i,1)];
//        code = [code stringByAppendingFormat:@"0x%02X", aBuffer[0]];
//        
//        NSLog(@"%@", code);
//    }
    
    for (int i = 0; i < strSendCmd.length; i++) {
        [Konashi uartWrite:[strSendCmd characterAtIndex:i]];
    }
    if (![strSendCmd isEqualToString:@"\x1b"]) {
        // ESCが来た時は\rは送らない
        [Konashi uartWrite:13];
    }
}

// 
// Terminal
//

// for keyboard hide button
- (void) btnKeyboardHide {
    [txtvTerm resignFirstResponder];
    [txtTermCmd resignFirstResponder];
}

- (void) bbtnTermESC_Action {
//    [self sendTxCmdwor:@"\x1b"];
    [self trnsUartTx:@"\x1b"];
    NSLog(@"ESC");
}

// textField delegate
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField == txtTermCmd) {
//        strSendCmdPre = txtTermCmd.text;
        NSLog(@"%@", txtTermCmd.text);
        [self trnsUartTx:txtTermCmd.text];
        txtTermCmd.text = @"";
    }
    return YES;
}

//
// Keyboard 操作
//
// notification centerにキーボードが出たとか隠れたとかを登録する
- (void) registerForKeyboardNotifications {
    NSLog(@"Keyboard");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}
- (void) keyboardWasShown:(NSNotification*)aNotification {
    // Scrollしてずらす場合
    //    CGPoint scrollPoint = CGPointMake(0.0,40.0);    // 50ずらすと一応入力画面は全部はいる
    //    [svall setContentOffset:scrollPoint animated:YES];
    
    CGRect frmvTerm;
    frmvTerm.origin = txtvTerm.frame.origin;
    frmvTerm.size.width = txtvTerm.frame.size.width;
    frmvTerm.size.height = 285;
    txtvTerm.frame = frmvTerm;
    
    // Terminalではキーボードが出たらフォーカスを移す
    [txtTermCmd becomeFirstResponder];
}
- (void) keyboardWillBeHidden:(NSNotification*)aNotification {

    CGRect frmvTerm;
    frmvTerm.origin = txtvTerm.frame.origin;
    frmvTerm.size.width = txtvTerm.frame.size.width;
    frmvTerm.size.height = 504;
    txtvTerm.frame = frmvTerm;
}
//  キーボードを出す時にESC/キーボード収納ボタン/コマンド入力テキストボックスをつけたりつける
- (BOOL) textViewShouldBeginEditing:(UITextView*)textView {
    // 下記のスペースでaccessoryViewを作成する
    UIView* accessoryView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];    // 高さ、幅
    accessoryView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]; // accessoryViewの色 ツールバーを使うから透明にしておく
    
    // ツールバーを作成する
    UIToolbar *tbTerm = [[UIToolbar alloc] init];
    tbTerm.frame = CGRectMake(250, 0, 70, 44);
    if (textView == txtvTerm) { // txtvTermでは長く表示
        tbTerm.frame = CGRectMake(0, 0, 320, 44);
    }
    [self.navigationController setToolbarHidden:NO animated:NO];
    tbTerm.tintColor = [UIColor blackColor];
    [accessoryView addSubview:tbTerm];
    
    NSMutableArray *tbItems = [NSMutableArray array];
    
    if (textView == txtvTerm) {
        // ESCボタン作成 ESCボタンはツールバー上に配置
        UIBarButtonItem *bbtnTermESC = [[UIBarButtonItem alloc] initWithTitle:@"ESC" style:UIBarButtonItemStyleBordered target:self action:@selector(bbtnTermESC_Action)];
        [tbItems addObject:bbtnTermESC];
        UIBarButtonItem *bbtnVariSp = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tbItems addObject:bbtnVariSp];
        
        // テキストフィールド作成 テキストフィールドはツールバー上にあるように見えるように配置
        // テキストフィールド作成とともに、そこで使用するキーボードの種類、特性を決定
        txtTermCmd = [[UITextField alloc] init];
        txtTermCmd.frame = CGRectMake(60, 8, 185, 30);
        txtTermCmd.borderStyle=UITextBorderStyleRoundedRect;
        txtTermCmd.keyboardType = UIKeyboardTypeASCIICapable;
        txtTermCmd.returnKeyType = UIReturnKeySend;
        txtTermCmd.autocapitalizationType = UITextAutocapitalizationTypeNone;
        txtTermCmd.autocorrectionType = UITextAutocorrectionTypeNo;
        txtTermCmd.delegate = self;
        [accessoryView addSubview:txtTermCmd];
        
        /* これを使えばツールバーにテキストフィールドを設置可能だが、飽くまでbarbuttonなのでフォーカスが当てられない
         CGRect frame = CGRectMake(0, 0, 185, 30);
         UITextField *textField = [[UITextField alloc] initWithFrame:frame];
         
         textField.borderStyle = UITextBorderStyleRoundedRect;
         textField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
         textField.keyboardType = UIKeyboardTypeDefault;
         bbtnTxtTermCmd = [[UIBarButtonItem alloc] initWithCustomView:textField];
         [tbItems addObject:bbtnTxtTermCmd];*/
    }
    
    // キーボード閉じるボタン作成 ツールバー上に配置
    UIBarButtonItem *bbtnKeyboard = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btnKeyboard"] style:UIBarButtonItemStyleBordered target:self action:@selector(btnKeyboardHide)];
    [tbItems addObject:bbtnKeyboard];
    
    [tbTerm setItems:tbItems];
    
    textView.inputAccessoryView = accessoryView;
    
    return YES;
}

@end
