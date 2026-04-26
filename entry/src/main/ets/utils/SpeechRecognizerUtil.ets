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
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './Logger';

const LOG_TAG = 'SPEECH_RECOGNIZER';

export interface RecognitionResult {
  text: string;
  isFinal: boolean;
  timestamp: number;
}

export class SpeechRecognizerUtil {
  private asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private sessionId: string = 'video_subtitle_session';
  private onResultCallback: ((result: RecognitionResult) => void) | null = null;
  private onCompleteCallback: (() => void) | null = null;
  private onErrorCallback: ((error: string) => void) | null = null;

  async initEngine(): Promise<boolean> {
    try {
      const extraParam: Record<string, Object> = {
        'locate': 'CN',
        'recognizerMode': 'short'
      };
      
      const initParamsInfo: speechRecognizer.CreateEngineParams = {
        language: 'zh-CN',
        online: 1,
        extraParams: extraParam
      };

      return new Promise((resolve, reject) => {
        speechRecognizer.createEngine(initParamsInfo, 
          (err: BusinessError, speechRecognitionEngine: speechRecognizer.SpeechRecognitionEngine) => {
            if (!err) {
              Logger.info(LOG_TAG, 'ASR engine created successfully');
              this.asrEngine = speechRecognitionEngine;
              this.setupListener();
              resolve(true);
            } else {
              Logger.error(LOG_TAG, `Failed to create engine: ${err.code}, ${err.message}`);
              resolve(false);
            }
          });
      });
    } catch (error) {
      Logger.error(LOG_TAG, `Init engine error: ${JSON.stringify(error as BusinessError)}`);
      return false;
    }
  }

  private setupListener(): void {
    if (!this.asrEngine) {
      return;
    }

    const listener: speechRecognizer.RecognitionListener = {
      onStart: (sessionId: string, eventMessage: string) => {
        Logger.info(LOG_TAG, `onStart: ${sessionId}, ${eventMessage}`);
      },
      
      onEvent: (sessionId: string, eventCode: number, eventMessage: string) => {
        Logger.info(LOG_TAG, `onEvent: ${sessionId}, ${eventCode}, ${eventMessage}`);
      },
      
      onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
        Logger.info(LOG_TAG, `onResult: ${sessionId}`);
        
        if (result.result && this.onResultCallback) {
          const recognitionResult: RecognitionResult = {
            text: result.result,
            isFinal: result.isFinal ?? false,
            timestamp: Date.now()
          };
          this.onResultCallback(recognitionResult);
        }
      },
      
      onComplete: (sessionId: string, eventMessage: string) => {
        Logger.info(LOG_TAG, `onComplete: ${sessionId}, ${eventMessage}`);
        if (this.onCompleteCallback) {
          this.onCompleteCallback();
        }
      },
      
      onError: (sessionId: string, errorCode: number, errorMessage: string) => {
        Logger.error(LOG_TAG, `onError: ${sessionId}, ${errorCode}, ${errorMessage}`);
        if (this.onErrorCallback) {
          this.onErrorCallback(`Error ${errorCode}: ${errorMessage}`);
        }
      }
    };

    this.asrEngine.setListener(listener);
  }

  setResultCallback(callback: (result: RecognitionResult) => void): void {
    this.onResultCallback = callback;
  }

  setCompleteCallback(callback: () => void): void {
    this.onCompleteCallback = callback;
  }

  setErrorCallback(callback: (error: string) => void): void {
    this.onErrorCallback = callback;
  }

  startListening(): boolean {
    if (!this.asrEngine) {
      Logger.error(LOG_TAG, 'Engine not initialized');
      return false;
    }

    try {
      const audioParam: speechRecognizer.AudioInfo = {
        audioType: 'pcm',
        sampleRate: 16000,
        soundChannel: 1,
        sampleBit: 16
      };

      const extraParam: Record<string, Object> = {
        'vadBegin': 2000,
        'vadEnd': 3000,
        'maxAudioDuration': 60000
      };

      const recognizerParams: speechRecognizer.StartParams = {
        sessionId: this.sessionId,
        audioInfo: audioParam,
        extraParams: extraParam
      };

      this.asrEngine.startListening(recognizerParams);
      Logger.info(LOG_TAG, 'Started listening');
      return true;
    } catch (error) {
      Logger.error(LOG_TAG, `Start listening error: ${JSON.stringify(error as BusinessError)}`);
      return false;
    }
  }

  writeAudio(audioData: Uint8Array): boolean {
    if (!this.asrEngine) {
      return false;
    }

    try {
      this.asrEngine.writeAudio(this.sessionId, audioData);
      return true;
    } catch (error) {
      Logger.error(LOG_TAG, `Write audio error: ${JSON.stringify(error as BusinessError)}`);
      return false;
    }
  }

  finish(): void {
    if (this.asrEngine) {
      try {
        this.asrEngine.finish(this.sessionId);
        Logger.info(LOG_TAG, 'Finished recognition');
      } catch (error) {
        Logger.error(LOG_TAG, `Finish error: ${JSON.stringify(error as BusinessError)}`);
      }
    }
  }

  cancel(): void {
    if (this.asrEngine) {
      try {
        this.asrEngine.cancel(this.sessionId);
        Logger.info(LOG_TAG, 'Cancelled recognition');
      } catch (error) {
        Logger.error(LOG_TAG, `Cancel error: ${JSON.stringify(error as BusinessError)}`);
      }
    }
  }

  shutdown(): void {
    if (this.asrEngine) {
      try {
        this.asrEngine.shutdown();
        this.asrEngine = null;
        Logger.info(LOG_TAG, 'Engine shutdown');
      } catch (error) {
        Logger.error(LOG_TAG, `Shutdown error: ${JSON.stringify(error as BusinessError)}`);
      }
    }
  }
}
