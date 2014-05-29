/**
 * Created by oreva on 29.05.2014.
 */
package bb.modules
{
	internal class DLL
	{
		public var size:int = 0;

		public var head:Node;
		public var tail:Node;

		/**
		 */
		public function add(p_node:Node):void
		{
			if (tail)
			{
				tail.next = p_node;
				p_node.prev = tail;
				tail = p_node;
			}
			else head = tail = p_node;

			++size;
		}

		/**
		 */
		public function unlink(p_node:Node):void
		{
			if (p_node == tail)
			{
				tail = tail.prev;
				if (tail == null) head = null;
				else tail.next = null;
			}
			else if (p_node == head)
			{
				head = head.next;
				if (head == null) tail = null;
				else head.prev = null;
			}
			else
			{
				var prevNode:Node = p_node.prev;
				var nextNode:Node = p_node.next;

				prevNode.next = nextNode;
				nextNode.prev = prevNode;
			}

			p_node.dispose();

			--size;
		}

		/**
		 */
		public function clear():void
		{
			var currentNode:Node;

			while (tail)
			{
				currentNode = tail;
				tail = tail.prev;

				currentNode.unlink();
			}
		}
	}
}
