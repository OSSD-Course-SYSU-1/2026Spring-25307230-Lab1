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
import { Caption } from '../model/ViewModel';
import { Logger } from './Logger';

const LOG_TAG = 'SUBTITLE_GENERATOR';

export interface SubtitleSegment {
  index: number;
  startTime: number;
  endTime: number;
  text: string;
}

export class SubtitleGeneratorUtil {
  static formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    const ms = Math.floor((seconds % 1) * 1000);
    
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')},${ms.toString().padStart(3, '0')}`;
  }

  static generateSRT(segments: SubtitleSegment[]): string {
    let srtContent = '';
    
    for (const segment of segments) {
      const startTime = SubtitleGeneratorUtil.formatTime(segment.startTime);
      const endTime = SubtitleGeneratorUtil.formatTime(segment.endTime);
      
      srtContent += `${segment.index}\n`;
      srtContent += `${startTime} --> ${endTime}\n`;
      srtContent += `${segment.text}\n\n`;
    }
    
    return srtContent;
  }

  static parseSRT(srtContent: string): Caption[] {
    const captions: Caption[] = [];
    const blocks = srtContent.trim().split('\n\n');
    
    for (const block of blocks) {
      const lines = block.split('\n');
      if (lines.length >= 3) {
        const index = parseInt(lines[0]);
        const timeLine = lines[1];
        const text = lines.slice(2).join('\n');
        
        const timeMatch = timeLine.match(/(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})/);
        
        if (timeMatch) {
          const startHours = parseInt(timeMatch[1]);
          const startMinutes = parseInt(timeMatch[2]);
          const startSeconds = parseInt(timeMatch[3]);
          const startMs = parseInt(timeMatch[4]);
          
          const endHours = parseInt(timeMatch[5]);
          const endMinutes = parseInt(timeMatch[6]);
          const endSeconds = parseInt(timeMatch[7]);
          const endMs = parseInt(timeMatch[8]);
          
          const startTime = startHours * 3600 + startMinutes * 60 + startSeconds + startMs / 1000;
          const endTime = endHours * 3600 + endMinutes * 60 + endSeconds + endMs / 1000;
          
          const caption: Caption = {
            text: text,
            startTime: Math.floor(startTime),
            endTime: Math.floor(endTime)
          };
          captions.push(caption);
        }
      }
    }
    
    return captions;
  }

  static generateCaptionsFromText(
    textSegments: string[],
    segmentDuration: number = 3
  ): Caption[] {
    const captions: Caption[] = [];
    
    for (let i = 0; i < textSegments.length; i++) {
      const text = textSegments[i].trim();
      if (text) {
        const caption: Caption = {
          text: text,
          startTime: i * segmentDuration,
          endTime: (i + 1) * segmentDuration
        };
        captions.push(caption);
      }
    }
    
    return captions;
  }

  static mergeCaptions(existing: Caption[], newOnes: Caption[]): Caption[] {
    const merged: Caption[] = [];
    for (let i = 0; i < existing.length; i++) {
      merged.push(existing[i]);
    }
    
    for (const newCaption of newOnes) {
      const overlapIndex = merged.findIndex(
        (c: Caption) => c.startTime <= newCaption.startTime && c.endTime >= newCaption.startTime
      );
      
      if (overlapIndex === -1) {
        merged.push(newCaption);
      } else {
        const existingCaption = merged[overlapIndex];
        const mergedCaption: Caption = {
          text: existingCaption.text + ' ' + newCaption.text,
          startTime: existingCaption.startTime,
          endTime: Math.max(existingCaption.endTime, newCaption.endTime)
        };
        merged[overlapIndex] = mergedCaption;
      }
    }
    
    return merged.sort((a: Caption, b: Caption) => a.startTime - b.startTime);
  }

  static adjustCaptionTiming(captions: Caption[], speed: number): Caption[] {
    if (speed === 1) {
      return captions;
    }
    
    const adjusted: Caption[] = [];
    for (const caption of captions) {
      const adjustedCaption: Caption = {
        text: caption.text,
        startTime: Math.floor(caption.startTime / speed),
        endTime: Math.floor(caption.endTime / speed)
      };
      adjusted.push(adjustedCaption);
    }
    
    return adjusted;
  }
}
