//
//  ViewController.h
//  wlTerm
//
//  Created by tom on 2013/04/08.
//  Copyright (c) 2013年 tom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate> {

    NSString *strRcv;

    UITextField *txtTermCmd;
}

// Terminal Window
@property (weak, nonatomic) IBOutlet UITextView *txtvTerm;

// barbutton
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bbtnFind;
- (IBAction)bbtnFind_Action:(id)sender;

@end
