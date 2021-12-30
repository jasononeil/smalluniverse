package smalluniverse.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.MacroApi;
using StringTools;

class JsonEncoderMacros {
	public static function build():Null<ComplexType> {
		switch Context.getLocalType() {
			case TInst(_, [type]):
				final typeId = type.getID(false);
				final encoderClassName = 'JsonEncoder_${typeId}'.replace(
					".",
					"_"
				);
				final complexType = type.toComplex();
				s // Return early if the type already exists.
				try {
					final existingType = Context.getType(encoderClassName);
					return existingType.toComplex();
				} catch (err:String) {}

				// Return early if this is the generics in the smalluniverse Page type definition
				if (
					typeId == "smalluniverse.Page.Action" ||
					typeId == "smalluniverse.Page.PageData"
				) {
					return null;
				}

				// Raise error if type is a type parameter and not a concrete type
				switch type {
					case TInst(classType, _):
						if (classType.get().kind.match(KTypeParameter(_))) {
							trace(actionId, pageDataId);
							Context.error(
								'JsonEncoder was called with the type parameter ${classType.get().name} which is a generic, but the type parameter must be a concrete type',
								Context.currentPos()
							);
						}
					default:
				}

				// Create a new class and return it's ComplexType
				final typeDefinition = macro class $encoderClassName implements smalluniverse.SmallUniverse.IJsonEncoder<$complexType> {
					public function new() {}

					public function encode(value:$complexType):String {
						return tink.Json.stringify(action);
					}

					public function decode(json:String):$complexType {
						return tink.Json.parse(actionJson);
					}
				}
				Context.defineType(typeDefinition);
				return Context.getType(encoderClassName).toComplex();
			default:
				Context.error(
					"JsonEncoder must be used with one type parameter",
					Context.currentPos()
				);
		}
		return null;
	}
}
#end
