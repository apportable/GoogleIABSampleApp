//
//  R.m
//  IAB Sample
//
//  Created by Sean on 7/18/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "R.h"

@implementation RDrawable

@bridge (static, field) gas0 = gas0;
@bridge (static, field) gas1 = gas1;
@bridge (static, field) gas2 = gas2;
@bridge (static, field) gas3 = gas3;
@bridge (static, field) gas4 = gas4;
@bridge (static, field) premium = premium;
@bridge (static, field) free = free;
@bridge (static, field) gas_inf = gas_inf;

@end

@implementation RLayout

@bridge (static, field) activity_main = activity_main;

@end

@implementation RId

@bridge (static, field) screen_main = screen_main;
@bridge (static, field) screen_wait = screen_wait;
@bridge (static, field) upgrade_button = upgrade_button;
@bridge (static, field) infinite_gas_button = infinite_gas_button;
@bridge (static, field) free_or_premium = free_or_premium;
@bridge (static, field) gas_gauge = gas_gauge;

@end