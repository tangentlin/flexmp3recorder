package ui
{
	
	import com.noteflight.standingwave3.elements.AudioDescriptor;
	import com.noteflight.standingwave3.elements.Sample;
	import com.noteflight.standingwave3.formats.WaveFile;
	import com.noteflight.standingwave3.performance.AudioPerformer;
	import com.noteflight.standingwave3.performance.ListPerformance;
	
	import encoders.Mp3Encoder;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.media.Microphone;
	import flash.utils.Timer;
	
	import org.bytearray.micrecorder.MicRecorder;
	import org.bytearray.micrecorder.encoder.WaveEncoder;
	import org.bytearray.micrecorder.events.RecordingEvent;
	
	import spark.components.supportClasses.ButtonBase;
	import spark.components.supportClasses.SkinnableComponent;
	import spark.components.supportClasses.ToggleButtonBase;
	import spark.core.IDisplayText;
	
	[SkinState("normal")]
	[SkinState("recording")]
	[SkinState("encoding")]
	public class RecorderControl extends SkinnableComponent
	{
		public static const SKINSTATE_NORMAL:String = "normal";
		public static const SKINSTATE_RECORDING:String = "recording";
		public static const SKINSTATE_ENCODING:String = "encoding";
		
		[SkinPart]
		public var recordButton:ToggleButtonBase;
		
		[SkinPart]
		public var activityLevelDisplay:IDisplayText;
		
		[SkinPart]
		public var encodeStatusDisplay:IDisplayText;
		
		[SkinPart]
		public var encodeButton:ButtonBase;
		
		private var recorder:MicRecorder;
		private var recording:Boolean = false;
		private var encoding:Boolean = false;
		
		private var encodingStatus:String;
		
		public function RecorderControl()
		{
			super();
			
			recorder = new MicRecorder(new WaveEncoder(), null, 50, 22);
			recorder.addEventListener(RecordingEvent.RECORDING, recorder_recording, false, 0, true);
			recorder.addEventListener(Event.COMPLETE, recorder_recordComplete, false, 0, true);

		}

		
		//--------------------------------------------------------------------------
		//
		//  Overrides
		//
		//--------------------------------------------------------------------------
		
		override protected function getCurrentSkinState():String
		{
			if ( recording )
			{
				return SKINSTATE_RECORDING;
			}
			
			if ( encoding )
			{
				return SKINSTATE_ENCODING;
			}
			
			return SKINSTATE_NORMAL;
		} 
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( currentActivityLevelChanged )
			{
				currentActivityLevelChanged = false;
				setActivityLevelDisplay();
			}
		}
		
		
		
		override protected function partAdded(partName:String, instance:Object) : void
		{
			super.partAdded(partName, instance);
			
			if ( instance == recordButton )
			{
				recordButton.addEventListener(MouseEvent.CLICK, recordButton_click, false, 0, true);
			}
			
			if ( instance == activityLevelDisplay )
			{
				setActivityLevelDisplay();
			}
			
			if ( instance == encodeStatusDisplay )
			{
				setEncodingStatus();
			}
			
			if ( instance == encodeButton )
			{
				encodeButton.addEventListener(MouseEvent.CLICK, encodeButton_click, false, 0, true);
			}
		}
		
		override protected function partRemoved(partName:String, instance:Object) : void
		{
			super.partRemoved(partName, instance);
			if ( instance == recordButton )
			{
				recordButton.removeEventListener(MouseEvent.CLICK, recordButton_click, false);
			}
			
			if ( instance == encodeButton )
			{
				encodeButton.removeEventListener(MouseEvent.CLICK, encodeButton_click, false);
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		private function setEncodingStatus():void
		{
			if ( encodeStatusDisplay )
			{
				encodeStatusDisplay.text = encodingStatus;
			}
		}
		
		private function setActivityLevelDisplay():void
		{
			if ( activityLevelDisplay )
			{
				if ( recording )
				{
					if ( !isNaN(currentActivityLevel) )
					{
						activityLevelDisplay.text = currentActivityLevel.toString();
					}
					else
					{
						activityLevelDisplay.text = "No activity is detected";
					}
				}
				else
				{
					activityLevelDisplay.text = "Not recoding";
				}
			}
		}
		
		private function endRecording():void
		{
			if ( recording )
			{
				recorder.stop();
				recording = false;
				
				invalidateProperties();
				invalidateSkinState();
			}
		}
		
		private function startRecording():void
		{
			if ( !recording )
			{
				recorder.record();
				recording = true;
				
				invalidateProperties();
				invalidateSkinState();
			}
		}
		
		private function startEncoding():void
		{
			if ( !encoding )
			{
				encoding = true;
				var encoder:Mp3Encoder = new Mp3Encoder();
				encoder.addEventListener(ProgressEvent.PROGRESS, encoder_progress, false, 0, true);
				encoder.addEventListener(Event.COMPLETE, encoder_complete, false, 0, true);
				encoder.encode(recorder.output);
				invalidateProperties();
				invalidateSkinState();
			}
		}

		private function endEncoding():void
		{
			if ( encoding )
			{
				encoding = false;
				invalidateProperties();
				invalidateSkinState();
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Event Handlers
		//
		//--------------------------------------------------------------------------
		
		private function recordButton_click(event:MouseEvent):void
		{
			if ( recordButton.selected )
			{
				startRecording();
			}
			else
			{
				endRecording();
			}
		}
		
		protected function recorder_recordComplete(event:Event):void
		{
		}
		
		
		private function encoder_complete(event:Event):void
		{
			if ( encoding )
			{
				var encoder:Mp3Encoder = event.target as Mp3Encoder;
				encoder.addEventListener(ProgressEvent.PROGRESS, encoder_progress, false, 0, true);
				encoder.addEventListener(Event.COMPLETE, encoder_complete, false, 0, true);
				endEncoding();
			}
		}
		
		private function encoder_progress(event:ProgressEvent):void
		{
			var percentFinished:Number = event.bytesLoaded * 100 / event.bytesTotal;
			encodingStatus = Math.floor(percentFinished) + "%";
			setEncodingStatus();
		}
		
		protected function recorder_recording(event:RecordingEvent):void
		{
			currentActivityLevel = recorder.microphone.activityLevel;
		}
		
		protected function encodeButton_click(event:MouseEvent):void
		{
			startEncoding();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		//---------------------------------
		//    currentActivityLevel
		//---------------------------------
		
		private var _currentActivityLevel:Number;
		private var currentActivityLevelChanged:Boolean;
		
		public function get currentActivityLevel():Number
		{
			return _currentActivityLevel;
		}
		
		public function set currentActivityLevel(value:Number):void
		{
			if ( value == _currentActivityLevel)
				return;
			
			_currentActivityLevel = value;
			currentActivityLevelChanged = true;
			invalidateProperties();
		}
		
		
	}
}


/*import flash.display.*;
import flash.events.*;
import flash.text.*;
import flash.net.*;	
import flash.media.*;
import flash.utils.*;
import fl.controls.Button;

import org.as3wavsound.WavSound;
import org.bytearray.micrecorder.MicRecorder;
import org.bytearray.micrecorder.encoder.WaveEncoder;
import org.bytearray.micrecorder.events.RecordingEvent;	

import com.noteflight.standingwave3.elements.*;
import com.noteflight.standingwave3.filters.*;
import com.noteflight.standingwave3.formats.*;
import com.noteflight.standingwave3.generators.*;
import com.noteflight.standingwave3.modulation.*;
import com.noteflight.standingwave3.output.*;
import com.noteflight.standingwave3.performance.*;
import com.noteflight.standingwave3.sources.*;
import com.noteflight.standingwave3.utils.*;	

import com.greensock.*;

import fr.kikko.lab.ShineMP3Encoder;

public class VOCWordToYourMp3 extends MovieClip {
	// mic vars
	public var recorder:MicRecorder = new MicRecorder(new WaveEncoder());	
	private var recording:Boolean = false;		
	// SW3 vars
	public var player:AudioPlayer = new AudioPlayer()
	//public var sequence:ListPerformance = new ListPerformance()		
	// mp3 vars
	private var mp3Encoder:ShineMP3Encoder;			
	private var myWavData:ByteArray = new ByteArray()
	private var myWavFile:ByteArray = new ByteArray()
	// UI vars
	public var wavbtn:Button
	// Sine vars
	private var speedX:Number = 1;
	private var speedAngle:Number = 0.3;
	private var amplitude:Number = 45;
	private var angle:Number = 0;
	private var xpos:Number = 0;
	private var ypos:Number = 0;		
	private var centerY:Number = 350;
	
	public var jtlogo:MovieClip;
	
	public function VOCWordToYourMp3()
	{
		btnrec.addEventListener(MouseEvent.CLICK, onBtnClick)
		btnrec.addEventListener(MouseEvent.ROLL_OVER, onBtnRoll)
		btnrec.addEventListener(MouseEvent.ROLL_OUT, onBtnRoll)			
		btnrec.buttonMode = true;
		statustxt.text = "click the shiny button to begin recording and then allow Flash access to your microphone";	
		
		recorder.addEventListener(RecordingEvent.RECORDING, onRecording)
		recorder.addEventListener(Event.COMPLETE, onRecordComplete)
		
		player.addEventListener(Event.COMPLETE, onPlayComplete)
		wavbtn.addEventListener(MouseEvent.CLICK, onWavClick)
		
		soundMeter.scaleX = 0
		//initSineDrawer()
	}
	
	public function onBtnClick(e:MouseEvent)		{		startRecording()		}
	public function onBtnRoll(e:MouseEvent)			{								}		
	
	public function initSineDrawer()
	{
		// Sine Drawing
		graphics.lineStyle(1.5, 0x000000);
		graphics.moveTo(0, 355);			
	}
	
	public function startRecording()
	{			
		if (!recording) 
		{
			TweenMax.to(btnrec, .3, {glowFilter:{color:0xFF0000, alpha:1, blurX:50, blurY:50}} )
			
			recorder.record() 
			
		} else if (recording) {
			recorder.stop()
			recording = false
			TweenMax.to(btnrec, .3, {glowFilter:{color:0xFF0000, alpha:0, blurX:10, blurY:10}} )				
		}
	}
	public function onRecording(e:RecordingEvent)
	{			
		statustxt.text = "make some noise!"	
		var al:Number = recorder.microphone.activityLevel;
		TweenMax.to(soundMeter, .1, {scaleX:al * .01, onUpdate:onActivitylevelUpdate});//, onUpdateParams:[al]})
		if (!recording) recording = true;
	}		
	public function onActivitylevelUpdate(al)
	{
		//statustxt.text = _activityLevel
		// draw a cool sine wave!
		xpos += speedX;
		ypos = centerY + Math.sin(angle) * amplitude * ((al > 20)? al / 100 : 1)
		angle += speedAngle;
		graphics.lineTo(xpos,ypos)
	}
	private function onRecordComplete(e:Event):void
	{
		soundMeter.scaleX = 0
		
		recording = false;
		statustxt.text = "recording complete"	
		
		var src = WaveFile.createSample(recorder.output) // this is fine
		
		// I think im not clearing out the old audio properly here somehow...
		var sequence = new ListPerformance()
		sequence.addSourceAt(0, src)
		var ap = new AudioPerformer(sequence, new AudioDescriptor())
		//player.play(ap)
		
		renderWav(ap, true)
		
		// save to wav?
		// new FileReference().save (recorder.output, "VOCariousRecording.wav")
	}
	private function renderWav(src, convertToMp3 = false)
	{
		var innerTimer = new Timer(10,0)
		var framesPerChunk:uint = 8192;
		
		innerTimer.addEventListener(TimerEvent.TIMER, handleRenderTimer)
		innerTimer.start()
		
		function handleRenderTimer(e:TimerEvent)
		{
			src.getSample(framesPerChunk).writeWavBytes(myWavData)
			
			var m = Math.min(src.frameCount, src.position + framesPerChunk)
			var n = Math.max(0, m - src.position)
			
			if (n == 0)
			{
				if (src.position > 0) finishRender() else trace("cancel rendering")
				
			} else {
				statustxt.text = "rendering audio: "+ Math.floor(src.position * 100 / src.frameCount) + "%";
			}
		}				
		function finishRender()
		{
			innerTimer.stop()
			statustxt.text = "finishing audio render"
			WaveFile.writeBytesToWavFile(myWavFile, myWavData, 44100, 2, 16)
			
			if (!convertToMp3)
			{
				wavbtn.enabled = true;
			} else {
				makeIntoMp3(myWavFile)
			}
		}				
	}
	private function makeIntoMp3(wav)
	{
		wav.position = 0
		mp3Encoder = new ShineMP3Encoder(wav);
		mp3Encoder.addEventListener(Event.COMPLETE, mp3EncodeComplete);
		mp3Encoder.addEventListener(ProgressEvent.PROGRESS, mp3EncodeProgress);
		//mp3Encoder.addEventListener(ErrorEvent.ERROR, mp3EncodeError);
		mp3Encoder.start();	
		
		function mp3EncodeProgress(e:ProgressEvent) : void 
		{
			statustxt.text = "encoding mp3: " + e.bytesLoaded + "%"
		}
		
		function mp3EncodeComplete(e: Event) : void 
		{
			statustxt.text = "mp3 encoding complete\n"
			statustxt.appendText("you can now save the mp3 to your desktop")
			wavbtn.enabled = true;					
		}					
	}
	private function onWavClick(e:MouseEvent)
	{			
		// WRITE ID3 TAGS
		var sba:ByteArray = mp3Encoder.mp3Data;
		sba.position =  sba.length - 128
		sba.writeMultiByte("TAG", "iso-8859-1");
		sba.writeMultiByte("Microphone Test 1-2, 1-2      "+String.fromCharCode(0), "iso-8859-1");	// Title
		sba.writeMultiByte("jordansthings                 "+String.fromCharCode(0), "iso-8859-1");	// Artist			
		sba.writeMultiByte("Jordan's Thingz Bop Volume 1  "+String.fromCharCode(0), "iso-8859-1");	// Album		
		sba.writeMultiByte("2010" + String.fromCharCode(0), "iso-8859-1");							// Year
		sba.writeMultiByte("www.jordansthings.com         " + String.fromCharCode(0), "iso-8859-1");// comments
		sba.writeByte(57);																		
		
		new FileReference().save(sba, "FlashMicrophoneTest.mp3")
	}
	private function onPlayComplete(e:Event)
	{
		statustxt.text = "playing complete";		
	}
}*/