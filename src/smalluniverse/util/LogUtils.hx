package smalluniverse.util;

using tink.CoreApi;

function getClassName(value:Any, ?pos:haxe.PosInfos):String {
	final cls = @:nullSafety(Off) Type.getClass(value);
	if (cls == null) {
		throw new Error('Could not find class of $value', pos);
	}
	return Type.getClassName(cls);
}
