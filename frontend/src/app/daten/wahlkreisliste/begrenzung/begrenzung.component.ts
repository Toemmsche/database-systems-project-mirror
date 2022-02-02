import { AfterViewInit, ChangeDetectorRef, Component, ElementRef, Input, OnInit, ViewChild } from '@angular/core';

@Component({
  selector: 'app-begrenzung',
  templateUrl: './begrenzung.component.html',
  styleUrls: ['./begrenzung.component.scss']
})
export class BegrenzungComponent implements OnInit, AfterViewInit {
  @ViewChild('path') path !: ElementRef<SVGPathElement>;

  @Input() svgPath !: string;
  @Input() height !: number;

  viewBox: string = "200 0 450 500";

  constructor(private readonly changeDetector: ChangeDetectorRef) { }

  ngOnInit(): void {
  }

  ngAfterViewInit(): void {
    const rect = this.path.nativeElement.getBBox();
    this.viewBox = `${rect.x} ${rect.y} ${rect.width} ${rect.height}`;
    this.changeDetector.detectChanges();
  }
}
