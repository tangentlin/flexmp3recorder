package encoders
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	
	import fr.kikko.lab.ShineMP3Encoder;
	
	import org.bytearray.micrecorder.encoder.WaveEncoder;
	
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="complete", type="flash.events.Event")]
	public class Mp3Encoder extends EventDispatcher
	{
		private var _mp3EncodingWeight:Number = 60;
		private var _wavEncodingWeight:Number = 40;
		private var _result:ByteArray;
		
		public static const WAVE_PHASE:int = 0;
		public static const MP3_PHASE:int = 1;
		
		public function Mp3Encoder(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function encode( soundBytes:ByteArray ):void
		{
			encodeWave( soundBytes );
		}
		
		private function encodeWave( soundBytes:ByteArray ):void
		{
			var wav:WavEncoder = new WavEncoder();
			wav.addEventListener(ProgressEvent.PROGRESS, wavEncoder_progress, false, 0, true);
			wav.addEventListener(Event.COMPLETE, wavEncoder_complete, false);
			wav.encode( soundBytes );
		}
		
		private function encodeMp3( wavBytes:ByteArray ):void
		{
			var mp3:WaveToMp3Encoder = new WaveToMp3Encoder();
			mp3.addEventListener(ProgressEvent.PROGRESS, mp3Encoder_progress, false, 0, true);
			mp3.addEventListener(Event.COMPLETE, mp3Encoder_complete, false);
			mp3.encode( wavBytes );
		}
		
		private function dispatchProgressEvent(currentPhase:int, finished:Number, totalSize:Number):void
		{
			var progress:Number;
			var total:Number = 100;
			
			if ( currentPhase == 0 )
			{
				progress = finished * wavEncodingWeight / totalSize;
			}
			else
			{
				progress = wavEncodingWeight + finished * mp3EncodingWeight / totalSize;
			}
			
			
			var pe:ProgressEvent = new ProgressEvent( ProgressEvent.PROGRESS, false, false, progress, total );
			dispatchEvent(pe);
		}
		
		
		private function dispatchCompleteEvent():void
		{
			dispatchEvent( new Event(Event.COMPLETE) );
		}
		
		//--------------------------------------------------------------------------
		//
		//  Event Handlers
		//
		//--------------------------------------------------------------------------
		
		
		private function mp3Encoder_complete(event:Event) : void 
		{
			var encoder:ShineMP3Encoder = event.target as ShineMP3Encoder;
			_result = encoder.mp3Data;
			
			encoder.removeEventListener( Event.COMPLETE, mp3Encoder_complete, false );
			encoder.removeEventListener( ProgressEvent.PROGRESS, mp3Encoder_progress, false );
			dispatchCompleteEvent();
		}
		
		private function mp3Encoder_progress(event:ProgressEvent) : void 
		{
			dispatchProgressEvent( MP3_PHASE, event.bytesLoaded, event.bytesTotal );
		}
		
		
		protected function wavEncoder_complete(event:Event):void
		{
			var encoder:WavEncoder = event.target as WavEncoder;
			encoder.removeEventListener( Event.COMPLETE, mp3Encoder_complete, false );
			encoder.removeEventListener( ProgressEvent.PROGRESS, mp3Encoder_progress, false );
			dispatchProgressEvent( WAVE_PHASE, 100, 100);
			encodeMp3( encoder.result );
			
		}
		
		protected function wavEncoder_progress(event:ProgressEvent):void
		{
			dispatchProgressEvent( WAVE_PHASE, event.bytesLoaded, event.bytesTotal );
			
		}
		
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		
		/**
		 * The result of the wave encoding 
		 * @return 
		 * 
		 */		
		public function get result():ByteArray
		{
			return _result;
		}
		
		
		
		
		/**
		 * Weight of mp3Encoding 
		 * @return 
		 * 
		 */		
		private function get mp3EncodingWeight():Number
		{
			return _mp3EncodingWeight;
		}
		
		private function set mp3EncodingWeight(value:Number):void
		{
			_mp3EncodingWeight = value;
			_wavEncodingWeight = 100 - value;
		}
		
		
		
		public function get wavEncodingWeight():Number
		{
			return _wavEncodingWeight;
		}

		public function set wavEncodingWeight(value:Number):void
		{
			_wavEncodingWeight = value;
			_mp3EncodingWeight = 100 - value;
		}


	}
}