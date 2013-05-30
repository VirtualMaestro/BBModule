package bb
{
	import bb.signals.BBSignal;

	import de.polygonal.ds.DLL;
	import de.polygonal.ds.DLLNode;

	import flash.display.Stage;
	import flash.events.Event;

	import bb.modules.BBModule;

	import flash.utils.getTimer;

	CONFIG::debug
	{
		import vm.classes.ClassUtil;
		import vm.debug.Assert;
	}
	/**
	 * Engine of module system.
	 */
	public class BBModuleEngine
	{
		/**
		 * You can set fixed time step, value should be greater than 0 - e.g. 30, 60 or some other (e.g. as fps of app).
		 * In that case delta time will always the same.
		 */
		public var fixedTimeStep:int = 0;

		//
		private var _stage:Stage;
		private var _listModules:DLL;
		private var _listModulesToRegistration:DLL;
		private var _listModulesToUpdating:DLL;

		/**
		 */
		public function BBModuleEngine(p_stage:Stage = null)
		{
			_stage = p_stage;

			//
			_listModules = new DLL();
			_listModulesToRegistration = new DLL();
			_listModulesToUpdating = new DLL();
		}

		/**
		 * Method creates and adds module to system.
		 * As parameter set class of module.
		 * (If class is not inheritor of BBModule class then generates exception - if debug version of lib).
		 */
		public function addModule(moduleClass:Class):BBModule
		{
			CONFIG::debug
			{
				Assert.isTrue(ClassUtil.isSubclassOf(moduleClass, BBModule), "ERROR! bb.BBModuleEngine.addModule: given moduleClass is not an inheritor of BBModule class!");
				Assert.isTrue(isModuleAlreadyInSystem(moduleClass) == false, "ERROR! bb.BBModuleEngine.addModule: given moduleClass already in system!");
			}

			var module:BBModule = new moduleClass();
			_listModulesToRegistration.append(module);

			checkForOnOffRegisterModulesLoop();

			return module;
		}

		/**
		 * Returns instance of module by given module class name.
		 * If such instance is not in a system returns null.
		 */
		public function getModule(moduleClass:Class):BBModule
		{
			var resultModule:BBModule = null;

			forEachModules(function (module:BBModule):Boolean
			{
				if (module is moduleClass)
				{
					resultModule = module;
					return false;
				}

				return true;
			});

			return resultModule;
		}

		/**
		 */
		private function registerModulesLoop(event:Event):void
		{
			var node:DLLNode = _listModulesToRegistration.head;
			var module:BBModule;
			while (node)
			{
				module = node.val as BBModule;
				module.onDispose.add(removeModuleHandler);
				module.onUpdate.add(updateModuleHandler);
				_listModules.append(module);
				module.z_onSystemInit.dispatch(this);

				node = node.next;
			}

			// clear list
			_listModulesToRegistration.clear(true);

			// send signal onInit for all registered modules
			forEachModules(function (module:BBModule):Boolean
			{
				module.onInit.dispatch();
				return true;
			});

			// send signal onReadyToUse for all registered bb.modules
			forEachModules(function (module:BBModule):Boolean
			{
				module.onReadyToUse.dispatch();
				return true;
			});

			//
			checkForOnOffRegisterModulesLoop();
		}

		/**
		 */
		private function removeModuleHandler(signal:BBSignal):void
		{
			var module:BBModule = signal.dispatcher as BBModule;
			_listModules.remove(module);
			if (module.isUpdate) _listModulesToUpdating.remove(module);
		}

		/**
		 */
		private function updateModuleHandler(signal:BBSignal):void
		{
			var module:BBModule = signal.dispatcher as BBModule;
			if (module.isUpdate) _listModulesToUpdating.append(module);
			else _listModulesToUpdating.remove(module);

			//
			checkForOnOffUpdateModulesLoop();
		}

		//
		private var _currentTime:int = 0;
		private var _deltaTime:int = 0;
		private var _prevTime:int = 0;

		/**
		 */
		private function updateModulesLoop(event:Event):void
		{
			_currentTime = getTimer();
			_deltaTime = (fixedTimeStep > 0) ? fixedTimeStep : (_currentTime - _prevTime);

			var node:DLLNode = _listModulesToUpdating.head;
			var curNode:DLLNode;
			while (node)
			{
				curNode = node;
				node = node.next;

				(curNode.val as BBModule).update(_deltaTime);
			}

			_prevTime = _currentTime;
		}

		//
		private var _registerLoopOn:Boolean = false;

		/**
		 */
		private function checkForOnOffRegisterModulesLoop():void
		{
			if (_stage == null) return;

			if (_listModulesToRegistration.size() > 0)
			{
				if (!_registerLoopOn) _stage.addEventListener(Event.ENTER_FRAME, registerModulesLoop);
				_registerLoopOn = true;
			}
			else
			{
				if (_registerLoopOn) _stage.removeEventListener(Event.ENTER_FRAME, registerModulesLoop);
				_registerLoopOn = false;
			}
		}

		//
		private var _updateLoopOn:Boolean = false;

		/**
		 */
		private function checkForOnOffUpdateModulesLoop():void
		{
			if (_stage == null) return;

			if (_listModulesToUpdating.size() > 0)
			{
				if (!_updateLoopOn)
				{
					_stage.addEventListener(Event.ENTER_FRAME, updateModulesLoop);
					_prevTime = getTimer();
				}

				_updateLoopOn = true;
			}
			else
			{
				if (_updateLoopOn) _stage.removeEventListener(Event.ENTER_FRAME, updateModulesLoop);
				_updateLoopOn = false;
			}
		}

		/**
		 * Makes iteration for each bb.modules in system.
		 * 'handler' should returns Boolean type - if false loop is halted.
		 */
		private function forEachModules(handler:Function):void
		{
			var node:DLLNode = _listModules.head;
			var curNode:DLLNode;

			while (node)
			{
				curNode = node;
				node = node.next;

				if (handler(curNode.val) == false) break;
			}
		}

		/**
		 */
		public function get stage():Stage
		{
			return _stage;
		}

		/**
		 */
		public function set stage(val:Stage):void
		{
			if ((_stage != null) || (val == null)) return;
			_stage = val;
			checkForOnOffRegisterModulesLoop();
		}

		CONFIG::debug
		private function isModuleAlreadyInSystem(moduleClass:Class):Boolean
		{
			var result:Boolean = false;
			forEachModules(function (module:BBModule):Boolean
			{
				return !(result = (module is moduleClass));
			});

			return result;
		}
	}
}