package encoders
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	
	import fr.kikko.lab.ShineMP3Encoder;

	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="complete", type="flash.events.Event")]
	public class WaveToMp3Encoder extends EventDispatcher
	{
		private var _result:ByteArray;
		
		public function WaveToMp3Encoder(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function encode( wav:ByteArray ):void
		{
			wav.position = 0;
			
			var mp3Encoder:ShineMP3Encoder = new ShineMP3Encoder(wav);
			mp3Encoder.addEventListener(Event.COMPLETE, mp3Encoder_complete, false, 0, true);
			mp3Encoder.addEventListener(ProgressEvent.PROGRESS, mp3Encoder_progress, false, 0, true);
			mp3Encoder.start();	
		}
		
		
		
		private function dispatchProgressEvent(finished:Number, totalSize:Number):void
		{
			var pe:ProgressEvent = new ProgressEvent( ProgressEvent.PROGRESS, false, false, finished, totalSize );
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
			dispatchProgressEvent( event.bytesLoaded, event.bytesTotal );
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


	}
}