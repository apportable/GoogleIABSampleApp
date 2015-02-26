//
//  R.h
//  IAB Sample
//
//  Created by Sean on 7/18/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <JavaFoundation/JavaObject.h>

BRIDGE_CLASS("com.apportable.bridgekitv3.iab.R$drawable")
@interface RDrawable : JavaObject

+ (int)gas0;
+ (int)gas1;
+ (int)gas2;
+ (int)gas3;
+ (int)gas4;
+ (int)premium;
+ (int)free;
+ (int)gas_inf;

@end

BRIDGE_CLASS("com.apportable.bridgekitv3.iab.R$layout")
@interface RLayout : JavaObject

+ (int)activity_main;

@end

BRIDGE_CLASS("com.apportable.bridgekitv3.iab.R$id")
@interface RId : JavaObject

+ (int)screen_main;
+ (int)screen_wait;
+ (int)upgrade_button;
+ (int)infinite_gas_button;
+ (int)free_or_premium;
+ (int)gas_gauge;

@end



