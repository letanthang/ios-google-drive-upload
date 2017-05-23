//
//  HomeViewController.h
//  ios-quickeditor
//
//  Created by Le Tan Thang on 5/23/17.
//  Copyright © 2017 Google Developers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GTLRDrive.h>
#import "QEFileEditDelegate.h"
#import <Google/SignIn.h>

@interface HomeViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, QEFileEditDelegate, GIDSignInDelegate, GIDSignInUIDelegate>
@property GTLRDriveService *driveService;
@property GTLRDrive_File *driveFile;
@property (weak, nonatomic) IBOutlet UIButton *authButton;


- (IBAction)signoutButtonClicked:(id)sender;
- (IBAction)refreshButtonClicked:(id)sender;

- (void)toggleActionButtons:(BOOL)enabled;
- (void)loadDriveFiles;

@end
