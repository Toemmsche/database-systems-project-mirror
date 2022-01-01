import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AQVergleichComponent } from './aqvergleich.component';

describe('AQVergleichComponent', () => {
  let component: AQVergleichComponent;
  let fixture: ComponentFixture<AQVergleichComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ AQVergleichComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(AQVergleichComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
