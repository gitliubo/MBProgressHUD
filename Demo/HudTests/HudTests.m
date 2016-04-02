//
//  HudTests.m
//  HudTests
//
//  Created by Matej Bukovinski on 31. 01. 16.
//  Copyright © 2016 Matej Bukovinski. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MBProgressHUD.h"


#define weakify(var) __weak typeof(var) weak_##var = var;

#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = weak_##var; \
_Pragma("clang diagnostic pop")


@interface HudTests : XCTestCase <MBProgressHUDDelegate>

@property (nonatomic) XCTestExpectation *hideExpectation;
@property (nonatomic, copy) dispatch_block_t hideChecks;

@end


@implementation HudTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Convenience

- (void)testNonAnimatedConvenienceHUDPresentation {
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    UIView *rootView = rootViewController.view;

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:NO];

    XCTAssertNotNil(hud, @"A HUD should be created.");
    XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view.");
    XCTAssertTrue(hud.removeFromSuperViewOnHide, @"removeFromSuperViewOnHide should be enabled");
    XCTAssertEqual(hud.alpha, 1.f, @"The HUD should be visible.");
    XCTAssertFalse(hud.hidden, @"The HUD should be visible.");

    XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible.");
    XCTAssertFalse([hud.bezelView.layer.animationKeys containsObject:@"opacity"], @"The opacity should NOT be animated.");

    XCTAssertEqualObjects([MBProgressHUD HUDForView:rootView], hud, @"The HUD should be found via the convenience operation.");

    XCTAssertTrue([MBProgressHUD hideHUDForView:rootView animated:NO], @"The HUD should be found and removed.");

    XCTAssertFalse([rootView.subviews containsObject:hud], @"The HUD should no longer be part of the view hierarchy.");
    XCTAssertEqual(hud.alpha, 0.f, @"The hud should be faded out.");
    XCTAssertNil(hud.superview, @"The HUD should no longer be part of the view hierarchy.");

    XCTAssertFalse([MBProgressHUD hideHUDForView:rootView animated:NO], @"A subsequent HUD hide operation should fail.");
}

- (void)testAnimatedConvenienceHUDPresentation {
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    UIView *rootView = rootViewController.view;

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootView animated:YES];
    hud.delegate = self;

    XCTAssertNotNil(hud, @"A HUD should be created.");
    XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view.");
    XCTAssertTrue(hud.removeFromSuperViewOnHide, @"removeFromSuperViewOnHide should be enabled");
    XCTAssertEqual(hud.alpha, 1.f, @"The HUD should be visible.");
    XCTAssertFalse(hud.hidden, @"The HUD should be visible.");

    XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible.");
    XCTAssertTrue([hud.bezelView.layer.animationKeys containsObject:@"opacity"], @"The opacity should be animated.");

    XCTAssertEqualObjects([MBProgressHUD HUDForView:rootView], hud, @"The HUD should be found via the convenience operation.");

    XCTAssertTrue([MBProgressHUD hideHUDForView:rootView animated:YES], @"The HUD should be found and removed.");

    XCTAssertTrue([rootView.subviews containsObject:hud], @"The HUD should still be part of the view hierarchy.");
    XCTAssertEqual(hud.alpha, 1.f, @"The hud should still be visible.");
    XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view.");

    weakify(self);
    self.hideChecks = ^{
        strongify(self);
        XCTAssertFalse([rootView.subviews containsObject:hud], @"The HUD should no longer be part of the view hierarchy.");
        XCTAssertEqual(hud.alpha, 0.f, @"The hud should be faded out.");
        XCTAssertNil(hud.superview, @"The HUD should no longer be part of the view hierarchy.");

        XCTAssertFalse([MBProgressHUD hideHUDForView:rootView animated:YES], @"A subsequent HUD hide operation should fail.");
    };

    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testNonAnimatedHudReuse {
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    UIView *rootView = rootViewController.view;

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    [rootView addSubview:hud];
    [hud showAnimated:NO];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    [hud hideAnimated:NO];
    [hud showAnimated:NO];

    XCTAssertEqualObjects(hud.superview, rootView, @"The hood should be added to the view.");
    XCTAssertEqual(hud.alpha, 1.f, @"The HUD should be visible.");
    XCTAssertFalse(hud.hidden, @"The HUD should be visible.");
    XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible.");

    [hud hideAnimated:NO];
    [hud removeFromSuperview];
}

- (void)testAnimatedImmediateHudReuse {
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    UIView *rootView = rootViewController.view;

    XCTestExpectation *hideExpectation = [self expectationWithDescription:@"The hud should have been hidden."];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    [rootView addSubview:hud];
    [hud showAnimated:YES];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    [hud hideAnimated:YES];
    [hud showAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqualObjects(hud.superview, rootView, @"The hood should be added to the view.");
        XCTAssertEqual(hud.alpha, 1.f, @"The HUD should be visible.");
        XCTAssertFalse(hud.hidden, @"The HUD should be visible.");
        XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible.");

        [hud hideAnimated:NO];
        [hud removeFromSuperview];

        [hideExpectation fulfill];
    });

    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testMinShowTime {
    UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    UIView *rootView = rootViewController.view;

    self.hideExpectation = [self expectationWithDescription:@"The hudWasHidden: delegate should have been called."];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:rootView];
    hud.delegate = self;
    hud.removeFromSuperViewOnHide = YES;
    hud.minShowTime = 2.;
    [rootView addSubview:hud];
    [hud showAnimated:YES];

    XCTAssertNotNil(hud, @"A HUD should be created.");

    [hud hideAnimated:YES];

    __block BOOL checkedAfterOneSecond = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Check that the hud is still visible
        XCTAssertEqualObjects(hud.superview, rootView, @"The hud should be added to the view.");
        XCTAssertEqual(hud.alpha, 1.f, @"The HUD should be visible.");
        XCTAssertFalse(hud.hidden, @"The HUD should be visible.");
        XCTAssertEqual(hud.bezelView.alpha, 1.f, @"The HUD should be visible.");
        checkedAfterOneSecond = YES;
    });

    weakify(self);
    self.hideChecks = ^{
        strongify(self);
        XCTAssertTrue(checkedAfterOneSecond);
    };

    [self waitForExpectationsWithTimeout:5. handler:nil];

    XCTAssertFalse([rootView.subviews containsObject:hud], @"The HUD should no longer be part of the view hierarchy.");
    XCTAssertEqual(hud.alpha, 0.f, @"The hud should be faded out.");
    XCTAssertNil(hud.superview, @"The HUD should no longer be part of the view hierarchy.");
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    if (self.hideChecks) self.hideChecks();
    self.hideChecks = nil;

    [self.hideExpectation fulfill];
    self.hideExpectation = nil;
}

@end
