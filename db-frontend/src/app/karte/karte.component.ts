import { AfterViewInit, Component, ElementRef, EventEmitter, Input, OnInit, Output, Renderer2, ViewChild } from '@angular/core';
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

  @ViewChild('mapContainer')
  mapContainerElement!: ElementRef<SVGElement>;

  @Output('ready')
  ready: EventEmitter<any> = new EventEmitter();

  viewId!: string;

  constructor(private readonly renderer: Renderer2) { }

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
        this.createMap();
      })
  }

  createMap(): void {
    this.bData.forEach(b => {
      const pathElement = this.renderer.createElement('path', 'svg');
      this.renderer.setAttribute(pathElement, 'd', b.begrenzung);
      this.renderer.setAttribute(pathElement, 'id', `${this.viewId}_${b.wk_nummer}`);
      this.renderer.addClass(pathElement, 'begrenzung');
      const pathTooltipElement = this.renderer.createElement('title', 'svg');
      const pathTooltipTextElement = this.renderer.createText(`${b.wk_nummer} - ${b.wk_name}`);
      this.renderer.appendChild(pathTooltipElement, pathTooltipTextElement);
      this.renderer.appendChild(pathElement, pathTooltipElement)
      this.renderer.appendChild(this.mapContainerElement.nativeElement, pathElement);
    });
    this.ready.emit();
  }

  colorWahlkreis(nummer: number, color: string): void {
    document.getElementById(`${this.viewId}_${nummer}`)?.setAttribute('style', `fill: #${color};`);

  }

}
