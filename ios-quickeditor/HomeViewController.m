//
//  HomeViewController.m
//  ios-quickeditor
//
//  Created by Le Tan Thang on 5/23/17.
//  Copyright © 2017 Google Developers. All rights reserved.
//

#import "HomeViewController.h"
#import <GTLRDrive.h>
#import <Google/SignIn.h>

#import "QEFileEditViewController.h"
#import "QEUtilities.h"
@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Configure Google Sign-in.
    GIDSignIn* signIn = [GIDSignIn sharedInstance];
    signIn.delegate = self;
    signIn.uiDelegate = self;
    signIn.scopes = [NSArray arrayWithObjects:kGTLRAuthScopeDrive, nil];
    [signIn signInSilently];
    
    self.driveService = [[GTLRDriveService alloc] init];
}

- (void)viewDidUnload
{
//    [self setAddButton:nil];
//    [self setRefreshButton:nil];
//    [self setAuthButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    GIDGoogleUser *currentUser = [GIDSignIn sharedInstance].currentUser;
    NSLog(@"user = %@", currentUser);
    if (!currentUser) {
        [self toggleActionButtons:NO];
        [self showSignIn];
    }
}
- (void)showSignIn {
    [[GIDSignIn sharedInstance] signIn];
}
- (NSURL *)getDocumentDirectory {
    
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    return urls[0];
    
}
- (void)toggleActionButtons:(BOOL)enabled {
    //self.addButton.enabled = enabled;
    //self.refreshButton.enabled = enabled;
}
- (IBAction)takePhotoTapped:(id)sender {
    UIImagePickerController *vc = [[UIImagePickerController alloc] init];
    vc.sourceType = UIImagePickerControllerSourceTypeCamera;
    vc.delegate = self;
    
    [self presentViewController:vc animated:YES completion:nil];
    
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *picture = info[UIImagePickerControllerEditedImage];
    if (picture == nil) {
        picture = info[UIImagePickerControllerOriginalImage];
    }
    
    
    if (picture != nil) {
        [self saveFile:picture];
    }
    
}

UIImage *image1 = nil;
NSData *imageData = nil;
- (void)saveFile:(UIImage *)image {
    //NSString *fileName = [NSString stringWithFormat:@"savephoto-%f",[NSDate date].timeIntervalSince1970];
    NSString *fileName = @"myphoto2";
    fileName = [fileName stringByAppendingString:@".jpg"];
    NSURL *imagePath = [[self getDocumentDirectory] URLByAppendingPathComponent:fileName];
    NSData *jpegData = UIImageJPEGRepresentation(image, 80);
    
    UIImage *compressImage = [self resize:image to:384]; // 768/2
    imageData = UIImageJPEGRepresentation(compressImage, 30);
    
    NSError *error = nil;
    [jpegData writeToURL:imagePath options:NSDataWritingAtomic error:&error];
    NSLog(@"write return error: %@",[error localizedDescription]);
}


- (IBAction)saveToGD:(id)sender {
    GTLRUploadParameters *uploadParameters = nil;
    
    
    NSData *fileContent = imageData;
    uploadParameters = [GTLRUploadParameters uploadParametersWithData:fileContent MIMEType:@"image/jpeg"];
    
    
    GTLRDrive_File *metadata = [[GTLRDrive_File alloc] init];
    metadata.name = @"myphoto4.jpg";
    //metadata.mimeType = @"application/vnd.google-apps.photo";
    
    GTLRDriveQuery *query = nil;
    if (self.driveFile.identifier == nil || self.driveFile.identifier.length == 0) {
        // This is a new file, instantiate an insert query.
        query = [GTLRDriveQuery_FilesCreate queryWithObject:metadata
                                           uploadParameters:uploadParameters];
    } else {
        // This file already exists, instantiate an update query.
        query = [GTLRDriveQuery_FilesUpdate queryWithObject:metadata
                                                     fileId:self.driveFile.identifier
                                           uploadParameters:uploadParameters];
    }
    query.fields = @"id,name,modifiedTime,mimeType";
    UIAlertView *alert = [QEUtilities showLoadingMessageWithTitle:@"Saving file"
                                                         delegate:self];
    
    [self.driveService executeQuery:query
                  completionHandler:^(GTLRServiceTicket *ticket,
                                      GTLRDrive_File *updatedFile,
                                      NSError *error) {
                      [alert dismissWithClickedButtonIndex:0 animated:YES];
                      if (error == nil) {
                          self.driveFile = updatedFile;
                          
                          //[self toggleSaveButton];
                          //[self.delegate didUpdateFileWithIndex:self.fileIndex
                          //                            driveFile:self.driveFile];
                          //[self doneEditing:nil];
                      } else {
                          NSLog(@"Error: %@", error);
                          NSDictionary *errorInfo = [error userInfo];
                          NSData *errData = errorInfo[kGTMSessionFetcherStatusDataKey];
                          if (errData) {
                              NSString *dataStr = [[NSString alloc] initWithData:errData
                                                                        encoding:NSUTF8StringEncoding];
                              NSLog(@"Details: %@", dataStr);
                          }
                          [QEUtilities showErrorMessageWithTitle:@"Unable to save file"
                                                         message:[error description]
                                                        delegate:self];
                      }
                  }];
}

- (IBAction)signoutButtonClicked:(id)sender {
    NSLog(@"Signing out user");
    [[GIDSignIn sharedInstance] signOut];
    self.driveService.authorizer = nil;
    [self toggleActionButtons:NO];
    [self showSignIn];
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    GIDGoogleUser *currentUser = [GIDSignIn sharedInstance].currentUser;
    NSLog(@"user = %@", currentUser);
    
    if (currentUser) {
        self.driveService.authorizer = currentUser.authentication.fetcherAuthorizer;
        [self.authButton setTitle:@"Sign out" forState:UIControlStateNormal];
        [self toggleActionButtons:YES];
        //[self loadDriveFiles];
    }
}

- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    NSLog(@"User signed-out");
}
- (UIImage *)resize:(UIImage *)image to:(CGFloat)width {
    CGFloat scale = width / image.size.width;
    CGFloat height = image.size.height * scale;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), false, 0);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}
@end
