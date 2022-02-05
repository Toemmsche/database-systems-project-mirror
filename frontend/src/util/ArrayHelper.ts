import {WahlkreisParteiErgebnis} from "../model/WahlkreisParteiErgebnis";
import {ParteiErgebnisVergleich} from "../model/ParteiErgebnisVergleich";


/**
 * @description
 * Takes an Array<V>, and a grouping function,
 * and returns a Map of the array grouped by the grouping function.
 *
 * @param list An array of type V.
 * @param keyGetter A Function that takes the the Array type V as an input, and returns a value of type K.
 *                  K is generally intended to be a property key of V.
 *
 * @returns Map of the array grouped by the grouping function.
 */
export function groupBy<K, V>(list: Array<V>, keyGetter: (input: V) => K): Map<K, Array<V>> {
   const map = new Map<K, Array<V>>();
  list.forEach((item) => {
       const key = keyGetter(item);
       const collection = map.get(key);
       if (!collection) {
           map.set(key, [item]);
       } else {
           collection.push(item);
       }
  });
  return map;
}

export function sortWithSonstige(a : WahlkreisParteiErgebnis | ParteiErgebnisVergleich, b : WahlkreisParteiErgebnis | ParteiErgebnisVergleich) {
  if (a.partei == 'Sonstige') {
    return 1;
  } else if (b.partei == 'Sonstige') {
    return -1;
  }
  return b.abs_stimmen - a.abs_stimmen;
}

export function sortWithSameSorting(sorting: Array<WahlkreisParteiErgebnis | ParteiErgebnisVergleich>): (a: WahlkreisParteiErgebnis | ParteiErgebnisVergleich, b: WahlkreisParteiErgebnis | ParteiErgebnisVergleich) => number {
  return (a: WahlkreisParteiErgebnis | ParteiErgebnisVergleich, b: WahlkreisParteiErgebnis | ParteiErgebnisVergleich) => {
    const indexA = sorting.findIndex(r => r.partei == a.partei);
    const indexB = sorting.findIndex(r => r.partei == b.partei);
    return indexA - indexB;
  }
}

export function containsLowerCase(str: string, substr: string) {
  return str.toLowerCase().indexOf(substr.toLowerCase()) !== -1;
}
