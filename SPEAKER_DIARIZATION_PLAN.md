# Speaker Diarization Implementation Plan

## Overview

Apple's Speech Recognition framework has **limited speaker diarization capabilities** compared to specialized services, but we can implement a practical solution that works well for most meeting scenarios.

## Apple's Current Capabilities

### Available in Speech Framework:
- ✅ **Basic speaker change detection** (iOS 16+, macOS 13+)
- ✅ **Speaker confidence scores**
- ✅ **Timestamp-based segmentation**
- ✅ **Multiple speaker recognition** (limited)

### Limitations:
- ❌ **No speaker identification** (can't tell who is Speaker A vs Speaker B)
- ❌ **No voice fingerprinting** across sessions
- ❌ **No speaker labeling** with names
- ❌ **Limited to 2-3 speakers** effectively

## Implementation Strategy

### Phase 1: Basic Speaker Segmentation (Immediate)
```swift
// Add to apple_speech.swift
if #available(macOS 13.0, *) {
    request.requiresOnDeviceRecognition = true
    request.addsPunctuation = true

    // Enable speaker detection
    if let speakerRecognition = request.supportsOnDeviceSpeakerRecognition {
        request.shouldReportPartialResults = true
    }
}
```

**Output Format:**
```
[Speaker 1 - 00:00-00:15]: "Welcome everyone to today's meeting..."
[Speaker 2 - 00:15-00:32]: "Thanks John, let's start with the quarterly review..."
[Speaker 1 - 00:32-00:45]: "Absolutely, here are the key metrics..."
```

### Phase 2: Enhanced Detection (Medium Term)
```swift
// Implement speaker change detection
func detectSpeakerChanges(transcription: SFTranscription) -> [SpeakerSegment] {
    var segments: [SpeakerSegment] = []
    var currentSpeaker = 1

    for segment in transcription.segments {
        // Analyze confidence and timing patterns
        if shouldIndicateSpeakerChange(segment) {
            currentSpeaker = currentSpeaker == 1 ? 2 : 1
        }

        segments.append(SpeakerSegment(
            speaker: currentSpeaker,
            text: segment.substring,
            timeRange: segment.timeRange,
            confidence: segment.confidence
        ))
    }

    return segments
}
```

### Phase 3: Advanced Features (Future)
- **Voice activity detection** to separate speech from silence
- **Audio preprocessing** to improve speaker separation
- **Integration with video analysis** to correlate with screen changes
- **Meeting participant detection** using calendar integration

## Technical Implementation

### 1. Update `apple_speech.swift`

```swift
struct SpeakerSegment {
    let speaker: Int
    let text: String
    let timeRange: TimeRange
    let confidence: Float
}

func transcribeWithSpeakers(audioPath: String) async throws -> [SpeakerSegment] {
    // Implementation for speaker-aware transcription
}
```

### 2. Update `transcribe_audio_snippets.sh`

```bash
# Add speaker diarization option
if [ "$ENABLE_SPEAKER_DIARIZATION" = "true" ]; then
    transcription=$("$SCRIPT_DIR/bin/apple_speech" "$audio_file" --speakers --metadata)
else
    transcription=$("$SCRIPT_DIR/bin/apple_speech" "$audio_file" --metadata)
fi
```

### 3. Enhanced Output Format

```
# Audio Transcription with Speaker Diarization
# Audio File: meeting_2024-01-15.m4a
# Duration: 1847 seconds
# Speakers Detected: 3
# Method: Apple Speech Recognition + Speaker Detection

[Speaker 1 - 00:00:00-00:00:12]: "Good morning everyone, let's get started with today's standup."

[Speaker 2 - 00:00:12-00:00:25]: "Thanks Sarah. I completed the user authentication feature yesterday."

[Speaker 3 - 00:00:25-00:00:31]: "Great work! Any blockers for today?"

[Speaker 2 - 00:00:31-00:00:45]: "No blockers. I'm moving on to the dashboard integration."
```

## Configuration Updates

### Add to `config.sh`:
```bash
# Speaker Diarization Configuration
ENABLE_SPEAKER_DIARIZATION="true"  # Enable speaker detection
SPEAKER_DETECTION_METHOD="apple"   # Options: "apple", "simple", "disabled"
SPEAKER_CONFIDENCE_THRESHOLD="0.7" # Minimum confidence for speaker changes
SPEAKER_MIN_SEGMENT_DURATION="2"   # Minimum seconds for speaker segment
SPEAKER_OUTPUT_FORMAT="timestamped" # Options: "simple", "timestamped", "json"
```

## Alternative Approaches

### 1. Simple Heuristic Method
- **Detect pauses** longer than 2-3 seconds
- **Analyze volume changes** and speech patterns
- **Use timing patterns** to infer speaker changes

### 2. Audio Analysis Integration
```bash
# Use ffmpeg for basic audio analysis
ffmpeg -i audio.m4a -af "silencedetect=noise=-30dB:duration=1" -f null -

# Extract volume levels and timing
ffmpeg -i audio.m4a -af "volumedetect" -f null -
```

### 3. External Service Integration (Future)
- **Google Cloud Speech-to-Text** (has excellent diarization)
- **AWS Transcribe** (supports speaker identification)
- **Azure Speech Services** (multi-speaker support)

## Implementation Timeline

### Week 1: Basic Implementation
- [ ] Update `apple_speech.swift` with speaker detection
- [ ] Add configuration options
- [ ] Test with simple 2-speaker scenarios

### Week 2: Enhanced Detection
- [ ] Implement speaker change detection logic
- [ ] Add confidence scoring
- [ ] Create formatted output with timestamps

### Week 3: Integration & Testing
- [ ] Integrate with transcription pipeline
- [ ] Test with real meeting recordings
- [ ] Optimize detection parameters

### Week 4: Advanced Features
- [ ] Add JSON output format
- [ ] Create speaker statistics
- [ ] Build search capabilities by speaker

## Limitations & Workarounds

### Current Limitations:
1. **No speaker naming** - speakers are just "Speaker 1", "Speaker 2"
2. **Limited accuracy** - may miss some speaker changes
3. **No cross-session persistence** - can't remember speakers between recordings

### Workarounds:
1. **Manual speaker mapping** - users can map Speaker 1 → "John", Speaker 2 → "Sarah"
2. **Video correlation** - use screen sharing patterns to infer speakers
3. **Calendar integration** - use meeting participants from calendar events
4. **Voice consistency analysis** - track speaker patterns within meetings

## Testing Strategy

### Test Scenarios:
1. **2-person conversation** - basic back-and-forth
2. **3-person meeting** - multiple participants
3. **Presentation style** - one primary speaker with questions
4. **Cross-talk scenarios** - overlapping speech
5. **Different audio quality** - phone calls, room recordings

### Success Metrics:
- **Speaker change accuracy** > 80%
- **Segment boundary accuracy** within 1-2 seconds
- **Processing time** < 2x real-time audio duration
- **False positive rate** < 15%

## Future Enhancements

### Integration Opportunities:
1. **Video analysis** - correlate with screen sharing changes
2. **Calendar data** - map speakers to meeting participants
3. **Voice training** - learn speaker characteristics over time
4. **Meeting context** - use agenda/topics to improve accuracy

### Advanced Features:
1. **Emotion detection** - analyze speaker sentiment
2. **Speaking time analytics** - who spoke the most
3. **Conversation flow** - visualize speaker interactions
4. **Action item extraction** - identify tasks assigned to speakers

This plan provides a practical path forward for speaker diarization while working within Apple's framework limitations. The key is starting simple and building up capabilities over time.