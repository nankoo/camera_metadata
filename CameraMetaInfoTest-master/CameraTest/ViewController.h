//
//  ViewController.h
//  CameraTest
//
//  Created by kakegawa.atsushi on 2013/06/04.
//  Copyright (c) 2013年 kakegawa.atsushi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
<UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UITextField *field;
    UIButton *btn;
}

- (IBAction)buttonDidTouch:(id)sender;

@end
