package smalluniverse.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.MacroApi;
using StringTools;

class PageJsonEncoderMacros {
    public static function build(): Null<ComplexType> {
        switch Context.getLocalType() {
            case TInst(_, [actionType, pageDataType]):
                final actionId = actionType.getID(false);
                final pageDataId = pageDataType.getID(false);
                final encoderClassName = 'PageJsonEncoder_${actionId}_${pageDataId}'.replace(".", "_");
                final actionComplexType = actionType.toComplex();
                final pageDataComplexType = pageDataType.toComplex();

                // Return early if the type already exists.
                try {
                    final existingType = Context.getType(encoderClassName);
                    return existingType.toComplex();
                } catch (err: String) {}

                // Return early if this is the generics in the smalluniverse Page type definition
                if (actionId == "smalluniverse.Page.Action" || pageDataId == "smalluniverse.Page.PageData") {
                    return null;
                }

                // Raise error if actionType and pageDataType are type parameters and not concrete types
                function errIfTypeIsATypeParam(t: Type) {
                    switch t {
                        case TInst(classType, _):
                            if (classType.get().kind.match(KTypeParameter(_))) {
                                trace(actionId, pageDataId);
                                Context.error('PageJsonEncoder was called with the type parameter ${classType.get().name} which is a generic, but the type parameter must be a concrete type', Context.currentPos());
                            }
                        default:
                    }
                }
                errIfTypeIsATypeParam(actionType);
                errIfTypeIsATypeParam(pageDataType);

                // Create a new class and return it's ComplexType
                final typeDefinition = macro class $encoderClassName implements smalluniverse.SmallUniverse.IPageJsonEncoder<$actionComplexType, $pageDataComplexType> {
                    public function new() {}

                    public function encodeAction(action:$actionComplexType):String {
                        return tink.Json.stringify(action);
                    }
                    
                    public function decodeAction(actionJson:String):$actionComplexType {
                        return tink.Json.parse(actionJson);
                    }

                    public function encodePageData(pageData:$pageDataComplexType):String {
                        return tink.Json.stringify(pageData);
                    }

                    public function decodePageData(pageDataJson:String):$pageDataComplexType {
                        return tink.Json.parse(pageDataJson);
                    }
                }
                Context.defineType(typeDefinition);
                return Context.getType(encoderClassName).toComplex();
            default:
                Context.error("Class with 2 type parameters expected", Context.currentPos());
        }
        return null;
    }
}
#end