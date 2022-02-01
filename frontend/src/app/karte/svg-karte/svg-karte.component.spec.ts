import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SvgKarteComponent } from './svg-karte.component';

describe('SvgKarteComponent', () => {
  let component: SvgKarteComponent;
  let fixture: ComponentFixture<SvgKarteComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ SvgKarteComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(SvgKarteComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
