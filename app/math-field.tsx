'use client';

import { useEffect, useRef, useState } from 'react';
import type { MathfieldElement } from 'mathlive';
import 'mathlive/fonts.css';

let mathLivePromise:Promise<void>|null=null;

function loadMathLive(){
  mathLivePromise??=import('mathlive').then(({MathfieldElement})=>{
    MathfieldElement.fontsDirectory=null;
    MathfieldElement.soundsDirectory=null;
  });
  return mathLivePromise;
}

function useMathLive(){
  const [ready,setReady]=useState(false);
  useEffect(()=>{
    let mounted=true;
    void loadMathLive().then(()=>{if(mounted)setReady(true)});
    return()=>{mounted=false};
  },[]);
  return ready;
}

type MathFormulaProps = {
  latex: string;
  label: string;
};

type MathAnswerFieldProps = {
  value: string;
  onChange: (latex: string, plainText: string) => void;
  label?: string;
};

export function MathFormula({ latex, label }: MathFormulaProps) {
  const fieldRef = useRef<MathfieldElement | null>(null);
  const ready=useMathLive();

  useEffect(() => {
    const field = fieldRef.current;
    if (!field||!ready) return;
    field.readOnly = true;
    field.smartFence = true;
    if (field.value !== latex) {
      field.setValue(latex, { silenceNotifications: true });
    }
  }, [latex,ready]);

  return (
    <math-field
      ref={fieldRef}
      className="formula-display"
      aria-label={label}
    >
      {latex}
    </math-field>
  );
}

export function MathAnswerField({
  value,
  onChange,
  label = 'Enter a mathematical answer',
}: MathAnswerFieldProps) {
  const fieldRef = useRef<MathfieldElement | null>(null);
  const ready=useMathLive();

  useEffect(() => {
    const field = fieldRef.current;
    if (!field||!ready) return;

    field.smartFence = true;
    field.smartMode = true;
    field.mathVirtualKeyboardPolicy = 'manual';

    const showKeyboard = () => {
      window.mathVirtualKeyboard.layouts = [
        'numeric',
        'symbols',
        'alphabetic',
      ];
      window.mathVirtualKeyboard.show();
    };
    const updateKeyboardSpace = () => {
      const height = window.mathVirtualKeyboard.boundingRect.height;
      document.documentElement.style.setProperty(
        '--math-keyboard-height',
        `${height}px`,
      );
    };
    const hideKeyboard = () => {
      window.mathVirtualKeyboard.hide();
      document.documentElement.style.removeProperty('--math-keyboard-height');
    };

    field.addEventListener('focusin', showKeyboard);
    field.addEventListener('focusout', hideKeyboard);
    window.mathVirtualKeyboard.addEventListener(
      'geometrychange',
      updateKeyboardSpace,
    );
    return () => {
      field.removeEventListener('focusin', showKeyboard);
      field.removeEventListener('focusout', hideKeyboard);
      window.mathVirtualKeyboard.removeEventListener(
        'geometrychange',
        updateKeyboardSpace,
      );
      hideKeyboard();
    };
  }, [ready]);

  useEffect(() => {
    const field = fieldRef.current;
    if (field&&ready&&field.value !== value) {
      field.setValue(value, { silenceNotifications: true });
    }
  }, [value,ready]);

  return (
    <div className="math-answer-wrap">
      <math-field
        ref={fieldRef}
        className="math-answer"
        aria-label={label}
        placeholder="\text{Enter your answer}"
        math-virtual-keyboard-policy="manual"
        onInput={(event) => {
          const field = event.currentTarget;
          onChange(field.value, field.getValue('ascii-math'));
        }}
      />
      <small className="math-answer-help">
        Use your keyboard or tap the math-keyboard button for fractions,
        powers, roots, symbols, and variables.
      </small>
    </div>
  );
}
