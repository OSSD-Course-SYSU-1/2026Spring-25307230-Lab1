/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 ("the License");
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
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { VideoPage } from './VideoPage';
import { Logger } from '../utils/Logger';
import { VideoPickerUtil, VideoSelectResult } from '../utils/VideoPickerUtil';
import { SpeechRecognizerUtil, RecognitionResult } from '../utils/SpeechRecognizerUtil';
import { SubtitleGeneratorUtil } from '../utils/SubtitleGeneratorUtil';
import { Caption } from '../model/ViewModel';

const LOG_TAG = 'INDEX';
const orientation = window.Orientation.LANDSCAPE;

@Entry
@Component
struct Index {
  @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack();
  @Provide('VideoUri') videoUri: string = '';
  @Provide('GeneratedCaptions') generatedCaptions: Caption[] = [];
  @State isRecognizing: boolean = false;
  @State recognitionProgress: string = '';
  private currentWindow: window.Window | null = null;
  private speechRecognizer: SpeechRecognizerUtil = new SpeechRecognizerUtil();
  private recognitionTexts: string[] = [];

  aboutToAppear(): void {
    try {
      window.getLastWindow(this.getUIContext().getHostContext())
        .then(async (topWindow) => {
          this.currentWindow = topWindow;
          topWindow.setPreferredOrientation(orientation, (err: BusinessError) => {
            const errCode: number = err.code;
            if (errCode) {
              Logger.error(LOG_TAG,
                `Failed to set window orientation. Cause code: ${err.code}, message: ${err.message}`);
              return;
            }
            topWindow.setWindowSystemBarEnable(['status', 'navigation']);
          });
        }).catch((err: BusinessError) => {
        Logger.error(LOG_TAG, `Failed to obtain the top window. Cause code: ${err.code}, message: ${err.message}`);
      });
    } catch (exception) {
      Logger.error(LOG_TAG, 'Failed to enter immersive. Cause:', JSON.stringify(exception));
    }
  }

  @Builder
  buttonBuilder(text: ResourceStr, isVideo: boolean) {
    Button(text)
      .fontWeight(500)
      .fontSize(16)
      .width('50%')
      .fontColor('rgb(10,89,247)')
      .backgroundColor('rgba(0,0,0,0.05)')
      .enabled(this.videoUri !== '')
      .opacity(this.videoUri !== '' ? 1 : 0.4)
      .onClick(async () => {
        await this.currentWindow?.setWindowSystemBarEnable([]);
        this.pageStack.pushPathByName('videoPage', isVideo);
      })
  }

  @Builder
  PagesMap(name: string, isVideo: boolean) {
    if (name === 'videoPage') {
      VideoPage({ isVideo, currentWindow: this.currentWindow });
    }
  }

  async startSpeechRecognition(): Promise<void> {
    this.isRecognizing = true;
    this.recognitionProgress = '初始化语音识别引擎...';
    this.recognitionTexts = [];

    try {
      const initialized = await this.speechRecognizer.initEngine();
      if (!initialized) {
        Logger.error(LOG_TAG, 'Failed to initialize speech recognizer');
        this.recognitionProgress = '初始化失败';
        setTimeout(() => {
          this.isRecognizing = false;
        }, 2000);
        return;
      }

      this.speechRecognizer.setResultCallback((result: RecognitionResult) => {
        Logger.info(LOG_TAG, `Recognition result: ${result.text}`);
        this.recognitionProgress = `识别中: ${result.text}`;
        
        if (result.isFinal && result.text.trim()) {
          this.recognitionTexts.push(result.text.trim());
        }
      });

      this.speechRecognizer.setCompleteCallback(() => {
        Logger.info(LOG_TAG, 'Recognition completed');
        this.recognitionProgress = '生成字幕中...';
        
        if (this.recognitionTexts.length > 0) {
          const captions = SubtitleGeneratorUtil.generateCaptionsFromText(
            this.recognitionTexts,
            3
          );
          this.generatedCaptions = captions;
          Logger.info(LOG_TAG, `Generated ${captions.length} captions`);
          this.recognitionProgress = `已生成 ${captions.length} 条字幕`;
        } else {
          this.recognitionProgress = '未识别到语音内容';
        }
        
        setTimeout(() => {
          this.isRecognizing = false;
          this.speechRecognizer.shutdown();
        }, 2000);
      });

      this.speechRecognizer.setErrorCallback((error: string) => {
        Logger.error(LOG_TAG, `Recognition error: ${error}`);
        this.recognitionProgress = `错误: ${error}`;
        setTimeout(() => {
          this.isRecognizing = false;
          this.speechRecognizer.shutdown();
        }, 2000);
      });

      this.recognitionProgress = '请开始说话...';
      const started = this.speechRecognizer.startListening();
      if (!started) {
        Logger.error(LOG_TAG, 'Failed to start listening');
        this.recognitionProgress = '启动识别失败';
        setTimeout(() => {
          this.isRecognizing = false;
        }, 2000);
      }
    } catch (error) {
      Logger.error(LOG_TAG, `Speech recognition error: ${JSON.stringify(error as BusinessError)}`);
      this.recognitionProgress = '识别过程出错';
      setTimeout(() => {
        this.isRecognizing = false;
      }, 2000);
    }
  }

  build() {
    Navigation(this.pageStack) {
      Column() {
        Text($r('app.string.demo_title'))
          .fontSize(30)
          .fontWeight(700)
      }
      .padding({ left: 36, top: 8 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 12 }) {
        Button($r('app.string.select_video'))
          .fontWeight(500)
          .fontSize(16)
          .width('50%')
          .fontColor(Color.White)
          .backgroundColor('rgb(10,89,247)')
          .onClick(async () => {
            const result = await VideoPickerUtil.selectVideo();
            if (result) {
              this.videoUri = result.uri;
              Logger.info(LOG_TAG, `Video selected: ${result.uri}`);
            }
          })

        if (this.isRecognizing) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Color.White)
            Text(this.recognitionProgress || '正在识别语音...')
              .fontColor(Color.White)
              .fontSize(14)
          }
          .width('50%')
          .height(40)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgb(52,152,219)')
          .borderRadius(20)
        } else {
          Button('生成字幕（语音识别）')
            .fontWeight(500)
            .fontSize(16)
            .width('50%')
            .fontColor(Color.White)
            .backgroundColor('rgb(46,139,87)')
            .enabled(this.videoUri !== '')
            .opacity(this.videoUri !== '' ? 1 : 0.4)
            .onClick(async () => {
              await this.startSpeechRecognition();
            })
        }

        this.buttonBuilder($r('app.string.av_caption'), false)
        this.buttonBuilder($r('app.string.video_caption'), true)
      }
      .width('100%')
      .position({ bottom: 16 })
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.PagesMap)
    .hideToolBar(true)
    .hideTitleBar(true)
    .titleMode(NavigationTitleMode.Full)
    .onNavBarStateChange((isVisible) => {
      if (isVisible && this.currentWindow) {
        this.currentWindow.setWindowSystemBarEnable(['status', 'navigation']);
      }
    })
  }
}