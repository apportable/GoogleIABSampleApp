//
//  IABSample.h
//  IAB Sample
//
//  Created by Philippe Hausler on 7/16/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <AndroidKit/AndroidActivity.h>

@class AndroidView;
@class Inventory;
@class IabResult;
@class Purchase;
@class AndroidIntent;

BRIDGE_CLASS("com.apportable.bridgekitv3.iab.IABSample")
@interface IABSample : AndroidActivity

- (void)run;

- (void)onDriveButtonClicked:(AndroidView *)view;

- (void)onBuyGasButtonClicked:(AndroidView *)view;

- (void)onUpgradeAppButtonClicked:(AndroidView *)view;

- (void)onInfiniteGasButtonClicked:(AndroidView *)view;

- (void)onActivityResult:(int)requestCode resultCode:(int)resultCode intent:(AndroidIntent *)intent;

@end
