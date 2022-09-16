#!/usr/bin/python2.7

import sys
import os
import errno
from imp import reload
from xml.etree import cElementTree as ET
from xml.etree.ElementTree import XMLParser

encoding = 'utf-8'
if sys.version_info.major < 3:
    reload(sys)
    sys.setdefaultencoding(encoding)

# normalize given language code to iOS language code format:
# https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LanguageandLocaleIDs/LanguageandLocaleIDs.html
def normalize_language_code(code):
    mappings = {
        'b+sr+Latn': 'sr-Latn'
    }
    # codes cannot be converted: 'vls', 'ang', 'szl', 'tzm'
    # return from mappings if exists
    if code in mappings:
        return mappings[code]
    # try to strip additional 'r' from the code
    r_tag = code.find('-r')
    if len(code) == 6 and r_tag != -1:
        result = code.replace('-r', '-')
        return result
    # return the original
    return code

# normalize given string by handling escapes and Android -> iOS format specifiers
def normalize_str(e):
    unique_tmp_val = '___'
    quote = '"'
    escaping_quote = '\\"'
    result = str(e).encode(encoding).strip()                    # convert input to a encoded string object and strip
    result = result.replace(escaping_quote, unique_tmp_val)     # replace escaping quotes with a temp value
    result = result.replace(quote, '')                          # remove all quotes
    result = result.replace(unique_tmp_val, escaping_quote)     # revert temp values to escaping quotes back
    result = result.replace('%s', '%@')                         # replace C-style specifiers
    for i in range(1, 6):
        result = result.replace('%' + str(i) + '$s', '%' + str(i) + '$@')   # replace C-style indexed specifiers
    result = result.replace('${app_name}', '%@')                # replace JSON-style specifiers
    result = result.replace('$ {app_name}', '%@')               # replace JSON-style specifiers
    result = result.replace('&amp;', '&')                       # replace ampersand
    result = result.replace('&lt;', '<')                        # replace less than
    result = result.replace('&gt;', '>')                        # replace greater than
    result = result.replace('\n', '')
    return result

def create_directories_for(output):
    if not os.path.exists(os.path.dirname(output)):
        try:
            os.makedirs(os.path.dirname(output))
        except OSError as exc:
            if exc.errno != errno.EEXIST:
                raise

def convert_file(input, output):
    create_directories_for(output)
    f_strings = open(output, 'w')

    # parse input XML into root
    root = ET.parse(input, parser=XMLParser(encoding=encoding)).getroot()

    for node in root.findall('string'):
        key = node.get('name')
        value = ET.tostring(node, encoding=encoding)
        value = value.replace('</string>', '')
        end_of_string_tag = value.find('>')
        if end_of_string_tag != -1:
            value = value[end_of_string_tag+1:]
        f_strings.write('"' + normalize_str(key) + '" = "' + normalize_str(value) + '";' + '\n')

    f_strings.close()

    # parse plurals and build stringsdict plist
    strings_plist = ET.Element('plist')
    strings_plist.set('version', '1.0')
    stringsDict = ET.SubElement(strings_plist, 'dict')
    for node in root.findall('plurals'):
        top_key = ET.SubElement(stringsDict, 'key')
        top_key.text = node.get('name')
        top_dict = ET.SubElement(stringsDict, 'dict')
        format_key = ET.Element('key')
        format_key.text = 'NSStringLocalizedFormatKey'
        top_dict.append(format_key)
        inner_string = ET.Element('string')
        inner_string.text = '%#@VARIABLE@'
        top_dict.append(inner_string)
        inner_key2 = ET.Element('key')
        inner_key2.text = 'VARIABLE'
        top_dict.append(inner_key2)
        inner_dict = ET.Element('dict')
        spec_type_key = ET.SubElement(inner_dict, 'key')
        spec_type_key.text = 'NSStringFormatSpecTypeKey'
        rule_type_key = ET.SubElement(inner_dict, 'string')
        rule_type_key.text = 'NSStringPluralRuleType'
        value_type_key = ET.SubElement(inner_dict, 'key')
        value_type_key.text = 'NSStringFormatValueTypeKey'
        value_type_value_string = ET.SubElement(inner_dict, 'string')
        value_type_value_string.text = 'd'
        for item in node.findall('item'):
            if item.text is not None and item.text != '':
                value = item.text
                quantity = item.get('quantity')
                key = ET.SubElement(inner_dict, 'key')
                key.text = normalize_str(quantity)
                string = ET.SubElement(inner_dict, 'string')
                string.text = normalize_str(value)
        top_dict.append(inner_dict)

    # write to stringsdict file
    if stringsDict.find('key') is not None:
        output_dict = str(output) + 'dict'
        tree = ET.ElementTree(element=strings_plist)
        tree.write(file_or_filename=output_dict, encoding=encoding, xml_declaration=False)
        os.system('plutil -convert xml1 ' + output_dict)

# os.system('./fetch_android_strings.sh')

print('\nAndroid strings fetched.\n')

res_folder = 'element-android/library/ui-strings/src/main/res'

for subdir, dirs, files in os.walk(res_folder):
    for dir in dirs:
        lang_code = dir
        lang_code = lang_code.replace('values-', '')
        if lang_code == 'values':
            lang_code = 'en'
        input = os.path.join(os.path.join(res_folder, dir), 'strings.xml')
        output = '../../ElementX/Resources/Localizations/' + normalize_language_code(lang_code) + '.lproj/Localizable.strings'
        input = os.path.realpath(input)
        output = os.path.realpath(output)
        print('--- Processing ' + lang_code + ' as: ' + normalize_language_code(lang_code))
        convert_file(input, output)

print('')
os.chdir('../..')
os.system('xcodegen')