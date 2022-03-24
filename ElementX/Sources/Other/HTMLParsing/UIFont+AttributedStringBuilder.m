//
//  UIFont+AttributedStringBuilder.h
//  ElementX
//
//  Created by Stefan Ceriu on 23/03/2022.
//  Copyright © 2022 Element. All rights reserved.
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
    if ([font.familyName.lowercaseString containsString:@"times"])
    {
        UIFontDescriptorSymbolicTraits symbolicTraits = (UIFontDescriptorSymbolicTraits)CTFontGetSymbolicTraits(ctFont);
        
        UIFontDescriptor *systemFontDescriptor = [UIFont systemFontOfSize:fontSize].fontDescriptor;
        
        UIFontDescriptor *finalFontDescriptor = [systemFontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
        font = [UIFont fontWithDescriptor:finalFontDescriptor size:fontSize];
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
