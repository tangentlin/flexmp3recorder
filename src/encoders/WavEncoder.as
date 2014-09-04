package encoders
{
	import com.noteflight.standingwave3.elements.AudioDescriptor;
	import com.noteflight.standingwave3.elements.Sample;
	import com.noteflight.standingwave3.formats.WaveFile;
	import com.noteflight.standingwave3.performance.AudioPerformer;
	import com.noteflight.standingwave3.performance.ListPerformance;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="complete", type="flash.events.Event")]
	public class WavEncoder extends EventDispatcher
	{
		private var wavBytes:ByteArray;
		private var processChunkSize:uint = 8192;
		private var waveSample:Sample;
		private var _result:ByteArray;
		
		public function WavEncoder(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function encode( rawSound:ByteArray ):void
		{
			wavBytes = new ByteArray();
			_result = new ByteArray();
			
			waveSample = WaveFile.createSample(rawSound);
			dispatchProgressEvent(0, waveSample.frameCount);
			
			var sequence:ListPerformance = new ListPerformance();
			sequence.addSourceAt(0, waveSample);
			
			var ap:AudioPerformer = new AudioPerformer(sequence, new AudioDescriptor());
			
			var innerTimer:Timer = new Timer(10,0);
			innerTimer.addEventListener(TimerEvent.TIMER, innerTimer_timer);
			innerTimer.start();
		}
		
		private function innerTimer_timer(event:TimerEvent):void
		{
			var length:Number = waveSample.frameCount;
			var currentPosition:Number = waveSample.position;
			var end:Number = Math.min(length, currentPosition + processChunkSize);
			var requestSize:Number = Math.max(0, end - currentPosition);
			
			if ( requestSize > 0 )
			{
				waveSample.getSample(processChunkSize).writeWavBytes(wavBytes);
				dispatchProgressEvent(end,length);
			}
			else
			{
				var timer:Timer = event.target as Timer;
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, innerTimer_timer);
				//TODO: Change hardcoded nature of the wave sample
				WaveFile.writeBytesToWavFile(result, wavBytes, 22000, 2, 16);
				dispatchCompleteEvent();
			}
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