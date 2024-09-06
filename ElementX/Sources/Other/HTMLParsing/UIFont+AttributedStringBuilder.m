//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

#import "UIFont+AttributedStringBuilder.h"

@import UIKit;
@import CoreText;
@import ObjectiveC;

#pragma mark - UIFont DTCoreText fix

@interface UIFont (vc_DTCoreTextFix)

+ (UIFont *)vc_fixedFontWithCTFont:(CTFontRef)ctFont;

@end

@implementation UIFont (vc_DTCoreTextFix)

+ (UIFont *)vc_fixedFontWithCTFont:(CTFontRef)ctFont {
    NSString *fontName = (__bridge_transfer NSString *)CTFontCopyName(ctFont, kCTFontPostScriptNameKey);

    CGFloat fontSize = CTFontGetSize(ctFont);
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];

    // On iOS 13+ "TimesNewRomanPSMT" will be used instead of "SFUI"
    // In case of "Times New Roman" fallback, use system font and reuse UIFontDescriptorSymbolicTraits.
    if ([font.familyName.lowercaseString containsString:@"times"]) {
        UIFontDescriptorSymbolicTraits symbolicTraits = (UIFontDescriptorSymbolicTraits)CTFontGetSymbolicTraits(ctFont);
        
        // Start with the body text style and update it to keep consistent line spacing with plain text messages.
        UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        fontDescriptor = [fontDescriptor fontDescriptorWithSize:fontSize];
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
        
        font = [UIFont fontWithDescriptor:fontDescriptor size:fontSize];
    }
    

    return font;
}

@end

#pragma mark - Implementation

@implementation UIFont(DTCoreTextFix)

// DTCoreText iOS 13 fix. See issue and comment here: https://github.com/Cocoanetics/DTCoreText/issues/1168#issuecomment-583541514
// Also see https://github.com/Cocoanetics/DTCoreText/pull/1245 for a possible future solution
+ (void)load
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        Class originalClass = object_getClass([UIFont class]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL originalSelector = @selector(fontWithCTFont:); // DTCoreText method we're overriding
        SEL ourSelector = @selector(vc_fixedFontWithCTFont:); // Use custom implementation
#pragma clang diagnostic pop
        
        Method originalMethod = class_getClassMethod(originalClass, originalSelector);
        Method swizzledMethod = class_getClassMethod(originalClass, ourSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

@end
