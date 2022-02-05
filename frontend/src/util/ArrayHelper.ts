import ParteiErgebnis from "../model/ParteiErgebnis";

export function sortWithSonstige(a: ParteiErgebnis, b: ParteiErgebnis) {
  if (a.partei == "Sonstige") {
    return 1;
  } else if (b.partei == "Sonstige") {
    return -1;
  }
  return b.abs_stimmen - a.abs_stimmen;
}

export function sortWithSameSorting(sorting: Array<ParteiErgebnis>): (a: ParteiErgebnis, b: ParteiErgebnis) => number {
  return (a: ParteiErgebnis, b: ParteiErgebnis) => {
    const indexA = sorting.findIndex(r => r.partei == a.partei);
    const indexB = sorting.findIndex(r => r.partei == b.partei);
    return indexA - indexB;
  }
}

export function containsLowerCase(str: string, substr: string) {
  return str.toLowerCase().indexOf(substr.toLowerCase()) !== -1;
}

export function mergeCduCsu<T extends ParteiErgebnis>(data: Array<T>): Array<T> {
  const onlyCduCsu = data.filter(pe => pe.partei === "CSU" || pe.partei === "CDU");
  let merged = {
    partei      : "UNION",
    partei_farbe: "000000",
    abs_stimmen : onlyCduCsu
      .map(pe => pe.abs_stimmen)
      .reduce((a, b) => a + b),
    rel_stimmen : onlyCduCsu
      .map(pe => pe.rel_stimmen)
      .reduce((a, b) => a + b)
  };
  // fill up remaining attributes
  merged = {
    ...data[0],
    ...merged // overwrite with new data
  }
  // @ts-ignore
  data.push(merged);
  return data.filter(pe => pe.partei !== "CSU" && pe.partei !== "CDU")
}
