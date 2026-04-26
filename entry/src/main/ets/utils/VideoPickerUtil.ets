/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './Logger';

const LOG_TAG = 'VIDEO_PICKER_UTIL';

export interface VideoSelectResult {
  uri: string;
  name?: string;
}

export class VideoPickerUtil {
  static async selectVideo(): Promise<VideoSelectResult | null> {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult: photoAccessHelper.PhotoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult.photoUris.length > 0) {
        const uri = photoSelectResult.photoUris[0];
        Logger.info(LOG_TAG, `Selected video URI: ${uri}`);
        return {
          uri: uri
        };
      }
      return null;
    } catch (error) {
      const err = error as BusinessError;
      Logger.error(LOG_TAG, `Failed to select video: code=${err.code}, message=${err.message}`);
      return null;
    }
  }
}
