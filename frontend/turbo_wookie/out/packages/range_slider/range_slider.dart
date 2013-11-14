
library range_slider;

import 'dart:html';
import 'dart:async';
import 'dart:math';

class RangeSlider {
  final Element $elmt;
  Element _$a;
  Element _$div_left;
  
  num _anim_value;
  num _value;
  
  num _start_offset;
  num _width;
  
  num _min = 0;
  num _max = 1;
  num _range;
  
  RangeSlider(Element this.$elmt) {
    $elmt.classes.addAll(const ["rangeslider-content", "rangeslider-content-horizontal"]);

    _$div_left = new DivElement();
    _$div_left.classes.add("rangeslider-range-left");
    $elmt.append(_$div_left);
    
    _$a = new AnchorElement();
    _$a.classes.addAll(const ["rangeslider-handle"]);
    _$a.draggable = true;
    $elmt.append(_$a);
    
    _$a.onDrag.listen(_onDrag);
    _$a.onDragStart.listen(_onDragStart);
    _$a.onDragEnd.listen(_onDragEnd);
    
    String value = $elmt.attributes["min"];
    if (value != null) {
      _min = double.parse(value);
    }
    value = $elmt.attributes["max"];
    if (value != null) {
      _max = double.parse(value);
    }
    _range = _max - _min;
    
    value = $elmt.attributes["slider_color"];
    if (value != null) {
      _$div_left.style.backgroundColor = value;
    }
    
    value = $elmt.attributes["value"];
    if (value != null) {
      this.value = double.parse(value);
    } else {
      $elmt.attributes["value"] = "0";
    }
  }

  void _onDragStart(MouseEvent evt) {
    DivElement $div = new DivElement();
    $div.style.position ="absolute";
    $div.style.top = "0px";
    $div.style.left = "0px";
    $div.style.width = "1px";
    $div.style.height = "1px";
    document.body.append($div);
    
    evt.dataTransfer.setDragImage($div, 0, 0);
    _start_offset = (evt.page.x - _$a.offsetLeft);
    _width = $elmt.getBoundingClientRect().width;
  }
  
  void _onDrag(MouseEvent evt) {
    num diff = evt.page.x - _start_offset;
    diff = min(diff, _width);
    diff = max(0, diff);
    _setUI(diff / _width);
    
    _anim_value = diff / _width;
    
    CustomEvent cevt = new CustomEvent("change", detail: { "value": _toClient(_anim_value) });
    $elmt.dispatchEvent(cevt);
  }
  
  void _onDragEnd(MouseEvent evt) {
    num diff = evt.page.x - _start_offset;
    diff = min(diff, _width);
    diff = max(0, diff);
    _setUI(diff / _width);
    
    _value = diff / _width;
    
    $elmt.attributes["value"] = _toClient(_value).toString();
    
    CustomEvent cevt = new CustomEvent("commit", detail: { "value": _toClient(_value) });
    $elmt.dispatchEvent(cevt);
  }
  
  num _toClient(num v) {
    return (v * _range) + _min;
  }
  
  num _fromClient(num v) {
    return (v - _min) / _range;
  }
  
  num get value {
    return _value;
  }
  
  void set value(num v) {
    _value = _fromClient(v);
    _setUI(_value);
  }
  
  void _setUI(num v) {
    v = v * 100;
    _$a.style.left = "${v.floor()}%";
    _$div_left.style.width = "${v.floor()}%";
  }
}
