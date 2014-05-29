/**
 * Created by oreva on 28.05.2014.
 */
package bb.modules
{
	import avmplus.getQualifiedClassName;

	/**
	 */
	internal class Assert
	{

		/**
		 */
		static public function isTrue(p_expression:Boolean, p_message:String, p_objectWhereHappened:* = null, p_methodName:String = null):void
		{
			if (!p_expression)
			{
				var message:String = "ERROR ";
				var methodName:String = p_methodName ? (p_methodName + "()") : "";

				if (p_objectWhereHappened)
				{
					message += "in " + getQualifiedClassName(p_objectWhereHappened);
					if (methodName != "") message += ".";
				}

				message += methodName + " : " + p_message;

				throw new Error(message);
			}
		}

	}
}
