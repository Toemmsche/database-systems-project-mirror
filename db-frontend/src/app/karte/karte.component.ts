import { AfterViewInit, Component, ElementRef, EventEmitter, Input, OnInit, Output, QueryList, Renderer2, ViewChild, ViewChildren } from '@angular/core';
import { Begrenzung } from 'src/model/Begrenzung';
import { REST_GET } from 'src/util';
import { v4 as uuid } from 'uuid';

@Component({
  selector: 'app-karte',
  templateUrl: './karte.component.html',
  styleUrls: ['./karte.component.scss']
})
export class KarteComponent implements OnInit, AfterViewInit {
  bData !: Array<Begrenzung>

  @Input() wahl: number = 20;

  @ViewChildren('begrenzung')
  begrenzungElements!: QueryList<ElementRef<SVGPathElement>>;

  @Output('ready')
  ready: EventEmitter<any> = new EventEmitter();

  viewId!: string;

  constructor() { }

  ngOnInit(): void {
    this.viewId = uuid();
  }

  ngAfterViewInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET(`${this.wahl}/karte`)
      .then(response => response.json())
      .then((data: Array<Begrenzung>) => {
        this.bData = data;
        this.ready.emit();
      })
  }

  bDataLoaded() {
    return this.bData != null && this.bData.length > 0;
  }

  colorWahlkreis(nummer: number, color: string): void {
    this.begrenzungElements.find(x => x.nativeElement.id === `${this.viewId}_${nummer}`)?.nativeElement.setAttribute('style', `fill: #${color};`);
  }

}
