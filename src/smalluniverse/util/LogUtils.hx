package smalluniverse.util;

using tink.CoreApi;

function getClassName(value:Any, ?pos:haxe.PosInfos):String {
	switch Type.typeof(value) {
		case TClass(cls):
			return Type.getClassName(cls);
		case TObject:
			final cls = @:nullSafety(Off) Type.getClass(value);
			if (cls == null) {
				throw new Error('Could not find class of $value', pos);
			}
			return Type.getClassName(cls);
		case unexpectedType:
			throw new Error(
				'Expected an object or a class, but it was ${unexpectedType}'
			);
	}
}
