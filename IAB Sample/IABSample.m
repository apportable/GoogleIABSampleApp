//
//  IABSample.m
//  IAB Sample
//
//  Created by Philippe Hausler on 7/16/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "IABSample.h"
#import "R.h"
#import <GoogleIAB/GoogleIAB.h>

#import <AndroidKit/AndroidImageView.h>
#import <AndroidKit/AndroidIntent.h>
#import <AndroidKit/AndroidAlertDialogBuilder.h>
#import <AndroidKit/AndroidSharedPreferencesEditor.h>
#import <AndroidKit/AndroidSharedPreferences.h>

extern NSString *ITEM_TYPE_SUBS;
extern NSString *ITEM_TYPE_INAPP;

// SKUs for our products: the premium upgrade (non-consumable) and gas (consumable)
static NSString *SKU_PREMIUM = @"premium1";
static NSString *SKU_GAS = @"gas1";

// SKU for our subscription (infinite gas)
static NSString *SKU_INFINITE_GAS = @"infinite_gas";

// (arbitrary) request code for the purchase flow
static int RC_REQUEST = 10001;

static int TANK_RES_IDS[5];

// How many units (1/4 tank is our unit) fill in the tank.
static int TANK_MAX = 4;

@interface IABSample()

// Does the user have the premium upgrade?
@property (nonatomic, assign) BOOL isPremium;

// Does the user have an active subscription to the infinite gas plan?
@property (nonatomic, assign) BOOL subscribedToInfiniteGas;

// Current amount of gas in tank, in units
@property (nonatomic, assign) int tank;

// Listener that's called when we finish querying the items and subscriptions we own
@property (nonatomic, copy) void (^gotInventoryListener)(IABResult *result, IABInventory *inventory);

// Called when consumption is complete
@property (nonatomic, copy) void (^consumeFinishedListener)(IABPurchase *purchase, IABResult *result);

// Callback for when a purchase is finished
@property (nonatomic, copy) void (^purchaseFinishedListener)(IABResult *result, IABPurchase *purchase);

@property (nonatomic, retain) IABHelper *helper;

@end

@implementation IABSample

@bridge (callback) run = run;

@bridge (callback) onDriveButtonClicked: = onDriveButtonClicked;

@bridge (callback) onBuyGasButtonClicked: = onBuyGasButtonClicked;

@bridge (callback) onUpgradeAppButtonClicked: = onUpgradeAppButtonClicked;

@bridge (callback) onInfiniteGasButtonClicked: = onInfiniteGasButtonClicked;

@bridge (callback) onActivityResult:resultCode:intent: = onActivityResult;

- (void)initializeMembers
{
    __weak IABSample *weakSelf = self;

    TANK_RES_IDS[0] = RDrawable.gas0;
    TANK_RES_IDS[1] = RDrawable.gas1;
    TANK_RES_IDS[2] = RDrawable.gas2;
    TANK_RES_IDS[3] = RDrawable.gas3;
    TANK_RES_IDS[4] = RDrawable.gas4;

    _gotInventoryListener = ^(IABResult *result, IABInventory *inventory) {
        NSLog(@"Query inventory finished.");

        // Have we been disposed of in the meantime? If so, quit.
        if (!weakSelf.helper) {
            return;
        }

        // Is it a failure?
        if (result.isFailure) {
            [weakSelf complain:[NSString stringWithFormat:@"Failed to query inventory: %@", result]];
            return;
        }

        NSLog(@"Query inventory was successful.");

        /*
         * Check for items we own. Notice that for each purchase, we check
         * the developer payload to see if it's correct! See
         * verifyDeveloperPayload().
         */

        // Do we have the premium upgrade?
        IABPurchase *premiumPurchase = [inventory getPurchase:SKU_PREMIUM];
        weakSelf.isPremium = (premiumPurchase != nil && [weakSelf verifyDeveloperPayload:premiumPurchase]);
        NSLog(@"User is %@", weakSelf.isPremium ? @"PREMIUM" : @"NOT PREMIUM");

        // Do we have the infinite gas plan?
        IABPurchase *infiniteGasPurchase = [inventory getPurchase:SKU_INFINITE_GAS];
        weakSelf.subscribedToInfiniteGas = (infiniteGasPurchase != nil && [weakSelf verifyDeveloperPayload:infiniteGasPurchase]);
        NSLog(@"User %@ infinite gas subscription.", weakSelf.subscribedToInfiniteGas ? @"HAS" : @"DOES NOT HAVE");

        // Check for gas delivery -- if we own gas, we should fill up the tank immediately
        IABPurchase *gasPurchase = [inventory getPurchase:SKU_GAS];
        if (gasPurchase != nil && [weakSelf verifyDeveloperPayload:gasPurchase]) {
            NSLog(@"We have gas. COnsuming it.");
            [weakSelf.helper consumeAsync:[inventory getPurchase:SKU_GAS] onConsumeFinished:weakSelf.consumeFinishedListener];
            return;
        }

        [weakSelf updateUi];
        [weakSelf setWaitScreen:NO];
        NSLog(@"Initial inventory query finished; enabling main UI.");
    };

    _consumeFinishedListener = ^(IABPurchase *purchase, IABResult *result) {
        NSLog(@"Consumption finished. Purchase: %@, result: %@", purchase, result);

        // if we were disposed of in the meantime, quit.
        if (!weakSelf.helper) {
            return;
        }

        // We know this is the "gas" sku because it's the only one we consume,
        // so we don't check which sku was consumed. If you have more than one
        // sku, you probably should check...
        if (result.isSuccess) {
            // successfully consumed, so we apply the effects of the item in our
            // game world's logic, which in our case means filling the gas tank a bit
            NSLog(@"Consumption successful. Provisioning.");
            weakSelf.tank = weakSelf.tank == TANK_MAX ? TANK_MAX : weakSelf.tank + 1;
            [weakSelf saveData];
            [weakSelf alert:[NSString stringWithFormat:@"You filled 1/4 tank. Your tank is now %d/4 full!", weakSelf.tank]];
        } else {
            [weakSelf complain:[NSString stringWithFormat:@"Error while consuming: %@", result]];
        }
        [weakSelf updateUi];
        [weakSelf setWaitScreen:NO];
        NSLog(@"End consumption flow.");
    };

    _purchaseFinishedListener = ^(IABResult *result, IABPurchase *purchase) {
        NSLog(@"Purchase finished: %@, purchase: %@", result, purchase);

        // if we were disposed of in the meantime, quit.
        if (weakSelf.helper == nil) {
            return;
        }

        if (result.isFailure) {
            [weakSelf complain:[NSString stringWithFormat:@"Error purchasing: %@", result]];
            [weakSelf setWaitScreen:NO];
            return;
        }

        if (![weakSelf verifyDeveloperPayload:purchase]) {
            [weakSelf complain:@"Error purchasing. Authenticity verification failed."];
            [weakSelf setWaitScreen:NO];
            return;
        }

        NSLog(@"Purchase successful.");

        if ([[purchase sku] isEqualToString:SKU_GAS]) {
            // bought 1/4 tank of gas. So consume it.
            NSLog(@"Purchase is gas. Starting gas consumption.");
            [weakSelf.helper consumeAsync:purchase onConsumeFinished:weakSelf.consumeFinishedListener];
        } else if ([[purchase sku] isEqualToString:SKU_PREMIUM]) {
            // bought the premium upgrade!
            NSLog(@"Purchase is premium upgrade. Congratulating user.");
            [weakSelf alert:@"Thank you for upgrading to premium!"];
            weakSelf.isPremium = true;
            [weakSelf updateUi];
            [weakSelf setWaitScreen:NO];
        } else if ([[purchase sku] isEqualToString:SKU_INFINITE_GAS]) {
            NSLog(@"Infinite gas subscription purchased.");
            [weakSelf alert:@"Thank you for subscribing to infinite gas!"];
            weakSelf.subscribedToInfiniteGas = YES;
            weakSelf.tank = TANK_MAX;
            [weakSelf updateUi];
            [weakSelf setWaitScreen:NO];
        }
    };
}

- (void)run
{
    [self initializeMembers];
    [self setContentViewByLayoutResID:[RLayout activity_main]];

    // load game data
    [self loadData];

    /* base64EncodedPublicKey should be YOUR APPLICATION'S PUBLIC KEY
     * (that you got from the Google Play developer console). This is not your
     * developer public key, it's the *app-specific* public key.
     *
     * Instead of just storing the entire literal string here embedded in the
     * program,  construct the key at runtime from pieces or
     * use bit manipulation (for example, XOR with some other string) to hide
     * the actual key.  The key itself is not secret information, but we don't
     * want to make it easy for an attacker to replace the public key with one
     * of their own and then fake messages from the server.
     */
    NSString *base64EncodedPublicKey = @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAshJV0evOMLbDkaxEn/muhS3i2WT70Z20JeFw6fBcA6po0M3Px0uCK7sT9xT2NdwE1RoxaMLF17wDqouIj6Uhzx3UYmMZQqYg90GJoFh6+1Vv5N7+b7TwJggGRdDLqafvXUDR+LH1CkUPdmhWEHEYdXPpQM5ZjRAazGQJjs9V3KAhXU594q7txWMWakm67DedrybW2Lla5l2oc37hZuHNYSNndkgywpHAiNJcsgDtvjtzAZK8d10h85eGWtob9dNAAqUxEoBxcxitAS53RftNK2HsiuaevFivlKYlu1CVzSx7dvR8Hajx7J14PmUGPry/HYTGXKdcgfe59AvO8oS4DQIDAQAB";

    // Some sanity checks to see if the developer (that's you!) really followed the
    // instructions to run this sample (don't put these checks on your app!)
    if ([base64EncodedPublicKey rangeOfString:@"CONSTRUCT_YOUR"].location != NSNotFound) {
        [NSException raise:@"Please put your app's public key in MainActivity.java. See README." format:@"Please put your app's public key in MainActivity.java. See README."];
    }
    if ([[self packageName] rangeOfString:@"com.example"].location != NSNotFound) {
        [NSException raise:@"Please change the sample's package name! See README." format:@"Please change the sample's package name! See README."];
    }

    // Create the helper, passing it our context and the public key to verify signatures with
    NSLog(@"Creating IAB helper.");
    _helper = [[IABHelper alloc] initWithContext:self andBase64EncodedPublicKey:base64EncodedPublicKey];

    // enable debug logging (for a production application, you should set this to false).
    [_helper enableDebugLogging:YES];

    // Start setup. This is asynchronous and the specified listener
    // will be called once setup completes.
    NSLog(@"Starting setup");
    [_helper startSetup:^(IABResult *result) {
        NSLog(@"Setup finished");

        if (!result.isSuccess) {
            [self complain:[NSString stringWithFormat:@"Problem setting up in-app billing: %@", result]];
            return;
        }

        // Have we been disposed of in the meantime? If so, quit.
        if (!_helper) {
            return;
        }

        // IAB is fully set up. Now, let's get an inventory of stuff we own.
        NSLog(@"Setup successful. Querying inventory.");
        [_helper queryInventoryAsync:_gotInventoryListener];
    } withSignatureVerifyListener:^BOOL(NSString *_signatureBase64, NSString *purchaseData, NSString *dataSignature) {
        // This is a naive signature verification process.
        
        //At least verify that the signature was real:
        return [IABSecurity verifyPurchase:base64EncodedPublicKey signedData:purchaseData signature:dataSignature];
        //You should probably do more to verify that everything is correct here. Validate purchaseData, etc. 
    }];
}

/** Verifies the developer payload of a purchase. */
- (BOOL) verifyDeveloperPayload:(IABPurchase *)p {
    NSString *payload = p.developerPayload;

    /*
     * TODO: verify that the developer payload of the purchase is correct. It will be
     * the same one that you sent when initiating the purchase.
     *
     * WARNING: Locally generating a random string when starting a purchase and
     * verifying it here might seem like a good approach, but this will fail in the
     * case where the user purchases an item on one device and then uses your app on
     * a different device, because on the other device you will not have access to the
     * random string you originally generated.
     *
     * So a good developer payload has these characteristics:
     *
     * 1. If two different users purchase an item, the payload is different between them,
     *    so that one user's purchase can't be replayed to another user.
     *
     * 2. The payload must be such that you can verify it even when the app wasn't the
     *    one who initiated the purchase flow (so that items purchased by the user on
     *    one device work on other devices owned by the user).
     *
     * Using your own server to store and verify developer payloads across app
     * installations is recommended.
     */

    return YES;
}

// updates UI to reflect model
- (void)updateUi {
    // update the car color to reflect premium status or lack thereof
    [((AndroidImageView *)[self findViewById:RId.free_or_premium]) setImageResource:_isPremium ? RDrawable.premium : RDrawable.free];

    // "Upgrade" button is only visible if the user is not premium
    [[self findViewById:RId.upgrade_button] setVisibility:_isPremium ? AndroidViewGone : AndroidViewVisible];

    // "Get infinite gas" button is only visible if the user is not subscribed yet
    [[self findViewById:RId.infinite_gas_button] setVisibility:_subscribedToInfiniteGas ? AndroidViewGone : AndroidViewVisible];

    // update gas gauge to reflect tank status
    if (_subscribedToInfiniteGas) {
        [((AndroidImageView *)[self findViewById:RId.gas_gauge]) setImageResource:RDrawable.gas_inf];
    } else {
        int index = _tank >= TANK_MAX ? TANK_MAX : _tank;
        [((AndroidImageView *)[self findViewById:RId.gas_gauge]) setImageResource:TANK_RES_IDS[index]];
    }
}

// Enables or disables the "please wait" screen.
- (void)setWaitScreen:(BOOL)set {
    [[self findViewById:RId.screen_main] setVisibility:set ? AndroidViewGone : AndroidViewVisible];
    [[self findViewById:RId.screen_wait] setVisibility:set ? AndroidViewVisible : AndroidViewGone];
}


- (void)complain:(NSString *)message
{
    NSLog(@"**** TrivialDrive Error: %@", message);
    [self alert:message];
}

- (void)alert:(NSString *)message
{
    AndroidAlertDialogBuilder *bld = [[AndroidAlertDialogBuilder alloc] initWithContext:self];
    [bld setMessageByCharSequence:message];
    [bld setNeutralButtonWithText:@"OK" onClickListener:nil];
    NSLog(@"Showing alert dialog: %@", message);
    [bld show];
}

- (void) saveData {

    /*
     * WARNING: on a real application, we recommend you save data in a secure way to
     * prevent tampering. For simplicity in this sample, we simply store the data using a
     * SharedPreferences.
     */

    JavaObject<AndroidSharedPreferencesEditor> *spe = [[self preferencesForMode:AndroidContextModePrivate] edit];
    [spe putInt:@"tank" intValue:_tank];
    [spe commit];
    NSLog(@"Saved data: tank = %d", _tank);
}


- (void)loadData
{
    id<AndroidSharedPreferences> sp = [self preferencesForMode:AndroidContextModePrivate];
    _tank = [sp intValueForKey:@"tank" defValue:2];
    NSLog(@"Loaded data: tank = %d", _tank);
}

- (void)onDriveButtonClicked:(AndroidView *)view {
    NSLog(@"Drive button clicked.");
    if (!_subscribedToInfiniteGas && _tank <= 0) {
        [self alert:@"Oh, no! You are out of gas! Try buying some!"];
    } else {
        if (!_subscribedToInfiniteGas) {
            --_tank;
        }
        [self saveData];
        [self alert:@"Vroooom, you drove a few miles."];
        [self updateUi];
        NSLog(@"Vrooom. Tank is now %d", _tank);
    }
}

- (void)onBuyGasButtonClicked:(AndroidView *)view {
    NSLog(@"Buy gas button clicked.");

    if (_subscribedToInfiniteGas) {
        [self complain:@"No need! You're subscribed to infinite gas. Isn't that awesome?"];
        return;
    }

    if (_tank >= TANK_MAX) {
        [self complain:@"Your tank is full. Drive around a bit!"];
        return;
    }
    // launch the gas purchase UI flow.
    // We will be notified of completion via mPurchaseFinishedListener
    [self setWaitScreen:YES];
    NSLog(@"Launching purchase flow for gas.");

    /* TODO: for security, generate your payload here for verification. See the comments on
     *        verifyDeveloperPayload() for more info. Since this is a SAMPLE, we just use
     *        an empty string, but on a production app you should carefully generate this. */
    NSString *payload = @"";
    [_helper launchPurchaseFlow:self sku:SKU_GAS requestCode:RC_REQUEST onIabPurchaseFinished:_purchaseFinishedListener extraData:payload];
}

- (void)onUpgradeAppButtonClicked:(AndroidView *)view {
    NSLog(@"Upgrade button clicked; launching purchase flow for upgrade.");
    [self setWaitScreen:YES];
    /* TODO: for security, generate your payload here for verification. See the comments on
     *        verifyDeveloperPayload() for more info. Since this is a SAMPLE, we just use
     *        an empty string, but on a production app you should carefully generate this. */
    NSString *payload = @"";
    [_helper launchPurchaseFlow:self sku:SKU_PREMIUM requestCode:RC_REQUEST onIabPurchaseFinished:_purchaseFinishedListener extraData:payload];
}

- (void)onInfiniteGasButtonClicked:(AndroidView *)view {
    if (!_helper.subscriptionsSupported) {
        [self complain:@"Subscriptions not supported on your device yet. Sorry!"];
        return;
    }

    NSString *payload = @"";
    [self setWaitScreen:YES];
    NSLog(@"Launching purchase flow for infinite gas subscription.");
    [_helper launchPurchaseFlow:self sku:SKU_INFINITE_GAS itemType:ITEM_TYPE_SUBS requestCode:RC_REQUEST onIabPurchaseFinished:_purchaseFinishedListener extraData:payload];
}

- (void)onActivityResult:(int)requestCode resultCode:(int)resultCode intent:(AndroidIntent *)intent {
    NSLog(@"onActivityResult(%d,%d,%@)", requestCode, resultCode, intent);
    if (_helper == nil) {
        return;
    }

    // Pass on the activity result to the helper for handling
    if (![_helper handleActivityResult:requestCode resultCode:resultCode intent:intent]) {
        // not handled, so handle it ourselves (here's where you'd
        // perform any handling of activity results not related to in-app
        // billing...
        [super onActivityResult:requestCode resultCode:resultCode intent:intent];
    }
    else {
        NSLog(@"onActivityResult handled by IABUtil.");
    }
}

@end
