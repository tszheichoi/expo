/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <ABI49_0_0React/ABI49_0_0RCTImageEditingManager.h>

#import <ABI49_0_0FBReactNativeSpec/ABI49_0_0FBReactNativeSpec.h>
#import <ABI49_0_0React/ABI49_0_0RCTConvert.h>
#import <ABI49_0_0React/ABI49_0_0RCTImageLoader.h>
#import <ABI49_0_0React/ABI49_0_0RCTImageLoaderProtocol.h>
#import <ABI49_0_0React/ABI49_0_0RCTImageStoreManager.h>
#import <ABI49_0_0React/ABI49_0_0RCTImageUtils.h>
#import <ABI49_0_0React/ABI49_0_0RCTLog.h>
#import <ABI49_0_0React/ABI49_0_0RCTUtils.h>
#import <UIKit/UIKit.h>

#import "ABI49_0_0RCTImagePlugins.h"

@interface ABI49_0_0RCTImageEditingManager () <ABI49_0_0NativeImageEditorSpec>
@end

@implementation ABI49_0_0RCTImageEditingManager

ABI49_0_0RCT_EXPORT_MODULE()

@synthesize moduleRegistry = _moduleRegistry;

/**
 * Crops an image and adds the result to the image store.
 *
 * @param imageRequest An image URL
 * @param cropData Dictionary with `offset`, `size` and `displaySize`.
 *        `offset` and `size` are relative to the full-resolution image size.
 *        `displaySize` is an optimization - if specified, the image will
 *        be scaled down to `displaySize` rather than `size`.
 *        All units are in px (not points).
 */
ABI49_0_0RCT_EXPORT_METHOD(cropImage
                  : (NSURLRequest *)imageRequest cropData
                  : (ABI49_0_0JS::NativeImageEditor::Options &)cropData successCallback
                  : (ABI49_0_0RCTResponseSenderBlock)successCallback errorCallback
                  : (ABI49_0_0RCTResponseSenderBlock)errorCallback)
{
  CGRect rect = {
    [ABI49_0_0RCTConvert CGPoint:@{
      @"x" : @(cropData.offset().x()),
      @"y" : @(cropData.offset().y()),
    }],
    [ABI49_0_0RCTConvert CGSize:@{
      @"width" : @(cropData.size().width()),
      @"height" : @(cropData.size().height()),
    }]
  };

  // We must keep a copy of cropData so that we can access data from it at a later time
  ABI49_0_0JS::NativeImageEditor::Options cropDataCopy = cropData;

  [[_moduleRegistry moduleForName:"ImageLoader"]
      loadImageWithURLRequest:imageRequest
                     callback:^(NSError *error, UIImage *image) {
                       if (error) {
                         errorCallback(@[ ABI49_0_0RCTJSErrorFromNSError(error) ]);
                         return;
                       }

                       // Crop image
                       CGSize targetSize = rect.size;
                       CGRect targetRect = {{-rect.origin.x, -rect.origin.y}, image.size};
                       CGAffineTransform transform = ABI49_0_0RCTTransformFromTargetRect(image.size, targetRect);
                       UIImage *croppedImage = ABI49_0_0RCTTransformImage(image, targetSize, image.scale, transform);

                       // Scale image
                       if (cropDataCopy.displaySize()) {
                         targetSize = [ABI49_0_0RCTConvert CGSize:@{
                           @"width" : @(cropDataCopy.displaySize()->width()),
                           @"height" : @(cropDataCopy.displaySize()->height())
                         }]; // in pixels
                         ABI49_0_0RCTResizeMode resizeMode = [ABI49_0_0RCTConvert ABI49_0_0RCTResizeMode:cropDataCopy.resizeMode() ?: @"contain"];
                         targetRect = ABI49_0_0RCTTargetRect(croppedImage.size, targetSize, 1, resizeMode);
                         transform = ABI49_0_0RCTTransformFromTargetRect(croppedImage.size, targetRect);
                         croppedImage = ABI49_0_0RCTTransformImage(croppedImage, targetSize, image.scale, transform);
                       }

                       // Store image
                       [[self->_moduleRegistry moduleForName:"ImageStoreManager"]
                           storeImage:croppedImage
                            withBlock:^(NSString *croppedImageTag) {
                              if (!croppedImageTag) {
                                NSString *errorMessage = @"Error storing cropped image in ABI49_0_0RCTImageStoreManager";
                                ABI49_0_0RCTLogWarn(@"%@", errorMessage);
                                errorCallback(@[ ABI49_0_0RCTJSErrorFromNSError(ABI49_0_0RCTErrorWithMessage(errorMessage)) ]);
                                return;
                              }
                              successCallback(@[ croppedImageTag ]);
                            }];
                     }];
}

- (std::shared_ptr<ABI49_0_0facebook::ABI49_0_0React::TurboModule>)getTurboModule:
    (const ABI49_0_0facebook::ABI49_0_0React::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<ABI49_0_0facebook::ABI49_0_0React::NativeImageEditorSpecJSI>(params);
}

@end

Class ABI49_0_0RCTImageEditingManagerCls()
{
  return ABI49_0_0RCTImageEditingManager.class;
}
