import { Component, ElementRef, Input, QueryList, ViewChildren } from '@angular/core';
import { Begrenzung } from 'src/model/Begrenzung';

@Component({
  selector: 'app-svg-karte',
  templateUrl: './svg-karte.component.html',
  styleUrls: ['./svg-karte.component.scss']
})
export class SvgKarteComponent {
  @ViewChildren('begrenzung')
  begrenzungElements!: QueryList<ElementRef<SVGPathElement>>;

  @Input() bData: Array<Begrenzung> = [];

  constructor() { }

  colorWahlkreis(nummer: number, color: string, border: string = '999999'): void {
    this.begrenzungElements.find(x => x.nativeElement.id === `karte_${nummer}`)
        ?.nativeElement
        .setAttribute('style', `fill: #${color}; stroke: #${border}`);
  }

  resetColors() {
    for (let wk_nummer = 1; wk_nummer <= 299; wk_nummer++) {
      this.colorWahlkreis(wk_nummer, 'FFFFFF');
    }
  }
}
