import 'package:yun_dao/src/entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:mustache4dart/mustache4dart.dart';
import 'template.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'dart:convert';

/**
 * 数据库管理类
 */
class EntityGenerator extends GeneratorForAnnotation<Entity> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // TODO: implement generateForAnnotatedElement
    String className = element.name + "Table";
    ConstantReader propertyListConstantReader = annotation.peek('propertyList');
    List<DartObject> dartList = propertyListConstantReader.listValue;
    List<Property> propertyList = List();
    final Function addProperty = (DartObject propertyDartObject) {
      final ConstantReader propertyConstantReader =
          ConstantReader(propertyDartObject);
      String name = propertyConstantReader.peek("name")?.stringValue;
      ConstantReader typeConstantReader =
          ConstantReader(propertyConstantReader.peek("type").objectValue);
      PropertyType type =
          PropertyType(value: typeConstantReader.peek("value").stringValue);
      bool isPrimary = propertyConstantReader.peek("isPrimary").boolValue;
      Property property =
          Property(name: name, type: type, isPrimary: isPrimary);
      propertyList.add(property);
    };
    dartList.forEach(addProperty);
    String jsonStr = json.encode(propertyList);
    String entityName = element.name;
    String formMap = "$entityName entity = $entityName();";
    String toMap = " var map = Map<String, dynamic>();\n";
    String primary = null;
    for (Property property in propertyList) {
      String propertyName = property.name;
      toMap = toMap + "map['$propertyName'] = entity.$propertyName;\n";
      formMap = formMap + "entity.$propertyName = map['$propertyName'];\n";
      if (property.isPrimary) {
        if (primary == null) {
          primary = propertyName;
        } else {
          throw '$entityName不能拥有两个主键!';
        }
      }
    }
    toMap = toMap + "return map;";
    formMap = formMap + "return entity;";

    String createSql = "";
    for (Property property in propertyList) {
      if (property == propertyList[propertyList.length - 1]) {
        createSql = createSql +
            property.name +
            "  " +
            property.type.value +
            (property.isPrimary ? "PRIMARY KEY" : "");
      } else {
        createSql =
            createSql + property.name + "  " + property.type.value + ",";
      }
    }
    if (primary == null) {
      throw '$entityName必须设置主键!';
    }
    return render(clazzTpl, <String, dynamic>{
      'className': className,
      'entityName': entityName,
      'tableName': annotation.peek("nameInDb")?.stringValue,
      "propertyList": "$jsonStr",
      "source": _getSource(element.source.fullName),
      "toMap": toMap,
      "formMap": formMap,
      "createSql": createSql,
      "primary": primary
    });
  }

  String wK(String key) {
    return "'${key}'";
  }

  String _getSource(String fullName) {
    String source = fullName.replaceAll("|lib", "");
    return source;
  }
}