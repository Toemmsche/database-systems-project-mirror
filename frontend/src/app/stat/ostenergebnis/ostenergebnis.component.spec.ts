import { ComponentFixture, TestBed } from '@angular/core/testing';

import { OstenergebnisComponent } from './ostenergebnis.component';

describe('OstenergebnisComponent', () => {
  let component: OstenergebnisComponent;
  let fixture: ComponentFixture<OstenergebnisComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ OstenergebnisComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(OstenergebnisComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
